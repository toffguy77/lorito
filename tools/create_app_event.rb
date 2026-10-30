# Creates the in-app event from fastlane/marketing/copy.json (app-store-presence) through
# the App Store Connect API: the event, its localizations (ru, es-ES, es-MX share the
# Russian copy), the card and details images, available in every territory.
#
# Usage: ruby tools/create_app_event.rb <event-start ISO8601> <days>
#   env: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, ASC_KEY_PATH, LORITO_APP_ID
# Leaves the event in Prepare for Submission; submit it for review separately.
require "openssl"
require "base64"
require "json"
require "net/http"
require "digest"
require "time"

start = Time.iso8601(ARGV[0] || abort("usage: create_app_event.rb <start ISO8601> <days>")).utc
finish = start + Integer(ARGV[1] || 14) * 86_400
copy = JSON.parse(File.read("fastlane/marketing/copy.json"))["inAppEvent"]
MEDIA = { "EVENT_CARD" => "fastlane/marketing/media/event-card.png",
          "EVENT_DETAILS_PAGE" => "fastlane/marketing/media/event-details.png" }.freeze
LOCALES = %w[ru es-ES es-MX].freeze

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

def upload(file, op_owner)
  bytes = File.binread(file)
  op_owner["attributes"]["uploadOperations"].each do |op|
    uri = URI(op["url"])
    req = Net::HTTP.const_get(op["method"].capitalize).new(uri)
    op["requestHeaders"].each { |h| req[h["name"]] = h["value"] }
    req.body = bytes.byteslice(op["offset"], op["length"])
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
    abort("upload part → #{res.code}") unless res.code.start_with?("2")
  end
  Digest::MD5.hexdigest(bytes)
end

app = ENV.fetch("LORITO_APP_ID")
# Re-running reuses an event with the same reference name (copy and media are replaced).
event = api(:get, "/v1/apps/#{app}/appEvents?limit=50")["data"].find { |e| e["attributes"]["referenceName"] == copy["referenceName"] }

territories = []
url = "/v1/territories?limit=200"
while url
  page = api(:get, url)
  territories.concat(page["data"].map { |t| t["id"] })
  url = page.dig("links", "next")
end

event ||= api(:post, "/v1/appEvents", { data: { type: "appEvents",
  attributes: { referenceName: copy["referenceName"], badge: copy["badge"], deepLink: copy["deepLink"],
                primaryLocale: "ru", priority: copy["priority"], purpose: copy["purpose"],
                territorySchedules: [{ territories: territories, publishStart: start.iso8601,
                                       eventStart: start.iso8601, eventEnd: finish.iso8601 }] },
  relationships: { app: { data: { type: "apps", id: app } } } } })["data"]
puts "event #{event["id"]}: #{start.iso8601} → #{finish.iso8601}, #{territories.size} territories"

existing = api(:get, "/v1/appEvents/#{event["id"]}/localizations")["data"]
LOCALES.each do |locale|
  attrs = { name: copy["name"], shortDescription: copy["shortDescription"], longDescription: copy["longDescription"] }
  loc = existing.find { |l| l["attributes"]["locale"] == locale }
  if loc
    api(:patch, "/v1/appEventLocalizations/#{loc["id"]}", { data: { type: "appEventLocalizations", id: loc["id"], attributes: attrs } })
  else
    loc = api(:post, "/v1/appEventLocalizations", { data: { type: "appEventLocalizations", attributes: attrs.merge(locale: locale),
      relationships: { appEvent: { data: { type: "appEvents", id: event["id"] } } } } })["data"]
  end
  api(:get, "/v1/appEventLocalizations/#{loc["id"]}/appEventScreenshots")["data"].each do |old|
    api(:delete, "/v1/appEventScreenshots/#{old["id"]}")
  end
  MEDIA.each do |kind, file|
    shot = api(:post, "/v1/appEventScreenshots", { data: { type: "appEventScreenshots",
      attributes: { fileName: File.basename(file), fileSize: File.size(file), appEventAssetType: kind },
      relationships: { appEventLocalization: { data: { type: "appEventLocalizations", id: loc["id"] } } } } })["data"]
    upload(file, shot)
    api(:patch, "/v1/appEventScreenshots/#{shot["id"]}", { data: { type: "appEventScreenshots", id: shot["id"],
      attributes: { uploaded: true } } })
  end
  puts "#{locale}: copy and media"
end
