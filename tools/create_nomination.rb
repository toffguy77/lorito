# Submits the featuring nomination from fastlane/marketing/copy.json (app-store-presence)
# through the App Store Connect API, linked to the app and its in-app event.
#
# Usage: ruby tools/create_nomination.rb <publish-start ISO8601> [--draft]
#   env: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, ASC_KEY_PATH, LORITO_APP_ID
require "openssl"
require "base64"
require "json"
require "net/http"
require "time"

start = Time.iso8601(ARGV[0] || abort("usage: create_nomination.rb <publish-start ISO8601> [--draft]")).utc
submit = !ARGV.include?("--draft")
copy = JSON.parse(File.read("fastlane/marketing/copy.json"))
nom = copy["featuringNomination"]

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
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
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

app = ENV.fetch("LORITO_APP_ID")
event = api(:get, "/v1/apps/#{app}/appEvents?limit=50")["data"]
        .find { |e| e["attributes"]["referenceName"] == copy["inAppEvent"]["referenceName"] }

relationships = { relatedApps: { data: [{ type: "apps", id: app }] } }
# Only an approved event can be linked; a draft one is announced with hasInAppEvents.
relationships[:inAppEvents] = { data: [{ type: "appEvents", id: event["id"] }] } if event&.dig("attributes", "eventState") == "APPROVED"

created = api(:post, "/v1/nominations", { data: { type: "nominations",
  attributes: { name: nom["name"], type: nom["type"], description: nom["description"], submitted: submit,
                publishStartDate: start.iso8601, deviceFamilies: %w[IPHONE IPAD], locales: %w[ru es-ES es-MX],
                supplementalMaterialsUris: nom["supplementalUrls"], hasInAppEvents: !event.nil?,
                launchInSelectMarketsFirst: false, preOrderEnabled: false },
  relationships: relationships } })["data"]
puts "nomination #{created["id"]}: #{created["attributes"]["state"]} · publish #{start.iso8601}"
