# Creates the custom product pages from fastlane/marketing/copy.json (app-store-presence)
# through the App Store Connect API: one page per entry, localizations ru, es-ES and
# es-MX (Russian copy), promotional text, and the listed scenes as iPhone 6.9" and
# iPad 13" screenshots from fastlane/screenshots/ru. Keywords are assigned in App Store
# Connect (web) once the keywords' version is approved.
#
# Usage: ruby tools/create_custom_product_pages.rb
#   env: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, ASC_KEY_PATH, LORITO_APP_ID
# A page whose name already exists is skipped.
require "openssl"
require "base64"
require "json"
require "net/http"
require "digest"

pages = JSON.parse(File.read("fastlane/marketing/copy.json"))["customProductPages"]
LOCALES = %w[ru es-ES es-MX].freeze
DEVICES = { "APP_IPHONE_67" => "Lorito iPhone", "APP_IPAD_PRO_3GEN_129" => "Lorito iPad" }.freeze

def token
  key = OpenSSL::PKey.read(File.read(ENV.fetch("ASC_KEY_PATH")))
  b64 = ->(s) { Base64.urlsafe_encode64(s, padding: false) }
  head = b64.({ alg: "ES256", kid: ENV.fetch("APP_STORE_CONNECT_KEY_ID"), typ: "JWT" }.to_json)
  body = b64.({ iss: ENV.fetch("APP_STORE_CONNECT_ISSUER_ID"), iat: Time.now.to_i, exp: Time.now.to_i + 1200,
                aud: "appstoreconnect-v1" }.to_json)
  der = key.sign(OpenSSL::Digest.new("SHA256"), "#{head}.#{body}")
  sig = OpenSSL::ASN1.decode(der).value.map { |v| v.value.to_s(2).rjust(32, "\x00") }.join
  "#{head}.#{body}.#{b64.(sig)}"
end
TOKEN = token

def api(method, path, body = nil)
  uri = URI(path.start_with?("http") ? path : "https://api.appstoreconnect.apple.com#{path}")
  req = Net::HTTP.const_get(method.capitalize).new(uri)
  req["Authorization"] = "Bearer #{TOKEN}"
  if body
    req["Content-Type"] = "application/json"
    req.body = body.to_json
  end
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
  abort("#{method} #{uri.path} → #{res.code}: #{res.body}") unless res.code.start_with?("2")
  res.body.to_s.empty? ? {} : JSON.parse(res.body)
end

def add_screenshot(set_id, file)
  bytes = File.binread(file)
  shot = api(:post, "/v1/appScreenshots", { data: { type: "appScreenshots",
    attributes: { fileName: File.basename(file).tr(" ", "_"), fileSize: bytes.bytesize },
    relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: set_id } } } } })["data"]
  shot["attributes"]["uploadOperations"].each do |op|
    uri = URI(op["url"])
    req = Net::HTTP.const_get(op["method"].capitalize).new(uri)
    op["requestHeaders"].each { |h| req[h["name"]] = h["value"] }
    req.body = bytes.byteslice(op["offset"], op["length"])
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
    abort("upload part → #{res.code}") unless res.code.start_with?("2")
  end
  api(:patch, "/v1/appScreenshots/#{shot["id"]}", { data: { type: "appScreenshots", id: shot["id"],
    attributes: { uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(bytes)  # Apple requires MD5 here (integrity check, not security) # nosemgrep } } })
end

app = ENV.fetch("LORITO_APP_ID")
existing = api(:get, "/v1/apps/#{app}/appCustomProductPages?limit=50")["data"].map { |p| p["attributes"]["name"] }

pages.each do |page|
  if existing.include?(page["referenceName"])
    puts "skip #{page["referenceName"]} (exists)"
    next
  end
  created = api(:post, "/v1/appCustomProductPages", {
    data: { type: "appCustomProductPages", attributes: { name: page["referenceName"] },
            relationships: { app: { data: { type: "apps", id: app } },
                             appCustomProductPageVersions: { data: [{ type: "appCustomProductPageVersions", id: "${v}" }] } } },
    included: [
      { type: "appCustomProductPageVersions", id: "${v}",
        relationships: { appCustomProductPageLocalizations: { data: [{ type: "appCustomProductPageLocalizations", id: "${l}" }] } } },
      { type: "appCustomProductPageLocalizations", id: "${l}",
        attributes: { locale: "ru", promotionalText: page["promotionalText"] } },
    ] })
  version = api(:get, "/v1/appCustomProductPages/#{created["data"]["id"]}/appCustomProductPageVersions")["data"].first
  locs = api(:get, "/v1/appCustomProductPageVersions/#{version["id"]}/appCustomProductPageLocalizations")["data"]
  LOCALES.each do |locale|
    loc = locs.find { |l| l["attributes"]["locale"] == locale }
    loc ||= api(:post, "/v1/appCustomProductPageLocalizations", { data: { type: "appCustomProductPageLocalizations",
      attributes: { locale: locale, promotionalText: page["promotionalText"] },
      relationships: { appCustomProductPageVersion: { data: { type: "appCustomProductPageVersions", id: version["id"] } } } } })["data"]
    DEVICES.each do |display, device|
      set = api(:post, "/v1/appScreenshotSets", { data: { type: "appScreenshotSets", attributes: { screenshotDisplayType: display },
        relationships: { appCustomProductPageLocalization: { data: { type: "appCustomProductPageLocalizations", id: loc["id"] } } } } })["data"]
      page["screens"].each { |scene| add_screenshot(set["id"], "fastlane/screenshots/ru/#{device}-#{scene}.png") }
    end
    puts "#{page["referenceName"]} · #{locale}: promo text and #{page["screens"].size}×2 screenshots"
  end
end
