# Creates the custom product pages from fastlane/marketing/copy.json (app-store-presence)
# through the App Store Connect API: one page per entry, localizations ru, es-ES and
# es-MX (Russian copy), promotional text, and the listed scenes as iPhone 6.9" and
# iPad 13" screenshots from fastlane/screenshots/ru. Keywords are assigned in App Store
# Connect (web) once the keywords' version is approved.
#
# Usage: ruby tools/create_custom_product_pages.rb
#        ruby tools/create_custom_product_pages.rb --new-version [--dry-run] [--submit]
#        ruby tools/create_custom_product_pages.rb --submit-only
#   env: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, ASC_KEY_PATH, LORITO_APP_ID
# A page whose name already exists is skipped.
#
# --new-version (store-screenshots-2-0-1): refresh existing pages without an app release —
# a new page version per page with the same promotional text and the current screenshots;
# keywords stay on the page. --dry-run only reads and prints the plan. --submit waits until
# Apple has processed every screenshot, adds the new versions to the open review submission
# (or a new one) and submits it. --submit-only does just that for each page's latest
# version not yet in review (after an interrupted --submit). Run only after the owner approves.
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
  # The API takes an MD5 of the file (an upload integrity check, not security).
  api(:patch, "/v1/appScreenshots/#{shot["id"]}", { data: { type: "appScreenshots", id: shot["id"],
    attributes: { uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(bytes) } } }) # nosemgrep: ruby.lang.security.weak-hashes-md5.weak-hashes-md5
end

app = ENV.fetch("LORITO_APP_ID")

def screenshot_files(page, device)
  page["screens"].map { |scene| "fastlane/screenshots/ru/#{device}-#{scene}.png" }.tap do |files|
    missing = files.reject { |f| File.exist?(f) }
    abort("missing screenshots: #{missing.join(", ")}") unless missing.empty?
  end
end

# Screenshots must finish Apple's processing before a version can join a review submission.
def wait_for_assets(version_id, timeout: 900)
  deadline = Time.now + timeout
  loop do
    states = []
    api(:get, "/v1/appCustomProductPageVersions/#{version_id}/appCustomProductPageLocalizations")["data"].each do |loc|
      api(:get, "/v1/appCustomProductPageLocalizations/#{loc["id"]}/appScreenshotSets")["data"].each do |set|
        api(:get, "/v1/appScreenshotSets/#{set["id"]}/appScreenshots?limit=50")["data"].each do |shot|
          states << shot.dig("attributes", "assetDeliveryState", "state")
        end
      end
    end
    abort("version #{version_id}: screenshot failed processing") if states.include?("FAILED")
    return if states.all? { |st| st == "COMPLETE" }
    abort("version #{version_id}: screenshots still processing after #{timeout} s") if Time.now > deadline
    puts "#{version_id}: #{states.count { |st| st != "COMPLETE" }} screenshot(s) processing…"
    sleep 20
  end
end

def submit_versions(app, version_ids)
  version_ids.each { |v| wait_for_assets(v) }
  sub = api(:get, "/v1/reviewSubmissions?filter[app]=#{app}&filter[state]=READY_FOR_REVIEW&include=items&limit=5")
  open_sub = sub["data"].first
  sub_id = open_sub ? open_sub["id"] : api(:post, "/v1/reviewSubmissions", { data: { type: "reviewSubmissions",
    attributes: { platform: "IOS" }, relationships: { app: { data: { type: "apps", id: app } } } } })["data"]["id"]
  in_sub = (sub["included"] || []).map { |i| i.dig("relationships", "appCustomProductPageVersion", "data", "id") }.compact
  version_ids.each do |v|
    next if in_sub.include?(v)
    api(:post, "/v1/reviewSubmissionItems", { data: { type: "reviewSubmissionItems",
      relationships: { reviewSubmission: { data: { type: "reviewSubmissions", id: sub_id } },
                       appCustomProductPageVersion: { data: { type: "appCustomProductPageVersions", id: v } } } } })
  end
  api(:patch, "/v1/reviewSubmissions/#{sub_id}", { data: { type: "reviewSubmissions", id: sub_id,
    attributes: { submitted: true } } })
  puts "submitted #{version_ids.size} page version(s) for review (#{sub_id})"
end

if ARGV.include?("--submit-only")
  ids = api(:get, "/v1/apps/#{app}/appCustomProductPages?limit=50")["data"].map do |cpp|
    next unless pages.any? { |p| p["referenceName"] == cpp["attributes"]["name"] }
    versions = api(:get, "/v1/appCustomProductPages/#{cpp["id"]}/appCustomProductPageVersions")["data"]
    latest = versions.max_by { |v| v["attributes"]["version"].to_i }
    latest["id"] if %w[PREPARE_FOR_SUBMISSION READY_FOR_REVIEW].include?(latest["attributes"]["state"])
  end.compact   # (no filter_map: macOS system Ruby is 2.6)
  abort("no page version waiting for review") if ids.empty?
  submit_versions(app, ids)
  exit
end

if ARGV.include?("--new-version")
  dry = ARGV.include?("--dry-run")
  live = api(:get, "/v1/apps/#{app}/appCustomProductPages?limit=50")["data"]
  new_versions = []
  pages.each do |page|
    cpp = live.find { |p| p["attributes"]["name"] == page["referenceName"] }
    abort("no custom product page «#{page["referenceName"]}»") unless cpp
    DEVICES.each_value { |device| screenshot_files(page, device) }
    if dry
      puts "#{page["referenceName"]}: new version · #{LOCALES.join("/")} · promo «#{page["promotionalText"][0, 40]}…» · " \
           "#{page["screens"].join(", ")} ×2 devices"
      next
    end
    version = api(:post, "/v1/appCustomProductPageVersions", { data: { type: "appCustomProductPageVersions",
      relationships: { appCustomProductPage: { data: { type: "appCustomProductPages", id: cpp["id"] } } } } })["data"]
    new_versions << version["id"]
    locs = api(:get, "/v1/appCustomProductPageVersions/#{version["id"]}/appCustomProductPageLocalizations")["data"]
    LOCALES.each do |locale|
      loc = locs.find { |l| l["attributes"]["locale"] == locale }
      loc ||= api(:post, "/v1/appCustomProductPageLocalizations", { data: { type: "appCustomProductPageLocalizations",
        attributes: { locale: locale, promotionalText: page["promotionalText"] },
        relationships: { appCustomProductPageVersion: { data: { type: "appCustomProductPageVersions", id: version["id"] } } } } })["data"]
      sets = api(:get, "/v1/appCustomProductPageLocalizations/#{loc["id"]}/appScreenshotSets")["data"]
      DEVICES.each do |display, device|
        set = sets.find { |x| x["attributes"]["screenshotDisplayType"] == display }
        if set
          # A new version may start with copies of the old screenshots: replace them.
          api(:get, "/v1/appScreenshotSets/#{set["id"]}/appScreenshots")["data"].each do |shot|
            api(:delete, "/v1/appScreenshots/#{shot["id"]}")
          end
        else
          set = api(:post, "/v1/appScreenshotSets", { data: { type: "appScreenshotSets", attributes: { screenshotDisplayType: display },
            relationships: { appCustomProductPageLocalization: { data: { type: "appCustomProductPageLocalizations", id: loc["id"] } } } } })["data"]
        end
        screenshot_files(page, device).each { |f| add_screenshot(set["id"], f) }
      end
      puts "#{page["referenceName"]} · #{locale}: new version #{version["id"]}"
    end
  end
  submit_versions(app, new_versions) if ARGV.include?("--submit") && !new_versions.empty?
  exit
end

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
