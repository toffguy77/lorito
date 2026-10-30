# Uploads the App Store app previews (app-store-presence) to an app version through the
# App Store Connect API — fastlane deliver does not handle previews.
#
# Usage: ruby tools/upload_app_previews.rb <version-string>
#   env: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, ASC_KEY_PATH, LORITO_APP_ID
# Files: fastlane/marketing/media/preview-iphone.mp4 → IPHONE_67,
#        fastlane/marketing/media/preview-ipad.mp4 → IPAD_PRO_3GEN_129,
# for every localization of that version. Existing previews in those sets are replaced.
require "openssl"
require "base64"
require "json"
require "net/http"
require "digest"

VERSION = ARGV[0] or abort("usage: upload_app_previews.rb <version-string>")
FILES = { "IPHONE_67" => "fastlane/marketing/media/preview-iphone.mp4",
          "IPAD_PRO_3GEN_129" => "fastlane/marketing/media/preview-ipad.mp4" }.freeze
POSTER = "00:00:05:00"

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

app = ENV.fetch("LORITO_APP_ID")
version = api(:get, "/v1/apps/#{app}/appStoreVersions?filter[versionString]=#{VERSION}&filter[platform]=IOS")["data"].first
abort("no version #{VERSION}") unless version
locs = api(:get, "/v1/appStoreVersions/#{version["id"]}/appStoreVersionLocalizations")["data"]

locs.each do |loc|
  locale = loc["attributes"]["locale"]
  sets = api(:get, "/v1/appStoreVersionLocalizations/#{loc["id"]}/appPreviewSets")["data"]
  FILES.each do |type, file|
    set = sets.find { |s| s["attributes"]["previewType"] == type }
    set ||= api(:post, "/v1/appPreviewSets", { data: { type: "appPreviewSets", attributes: { previewType: type },
      relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc["id"] } } } } })["data"]
    api(:get, "/v1/appPreviewSets/#{set["id"]}/appPreviews")["data"].each { |p| api(:delete, "/v1/appPreviews/#{p["id"]}") }

    bytes = File.binread(file)
    preview = api(:post, "/v1/appPreviews", { data: { type: "appPreviews",
      attributes: { fileName: File.basename(file), fileSize: bytes.bytesize, mimeType: "video/mp4", previewFrameTimeCode: POSTER },
      relationships: { appPreviewSet: { data: { type: "appPreviewSets", id: set["id"] } } } } })["data"]
    preview["attributes"]["uploadOperations"].each do |op|
      uri = URI(op["url"])
      req = Net::HTTP.const_get(op["method"].capitalize).new(uri)
      op["requestHeaders"].each { |h| req[h["name"]] = h["value"] }
      req.body = bytes.byteslice(op["offset"], op["length"])
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
      abort("upload part → #{res.code}") unless res.code.start_with?("2")
    end
    api(:patch, "/v1/appPreviews/#{preview["id"]}", { data: { type: "appPreviews", id: preview["id"],
      attributes: { uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(bytes) } } })
    puts "#{locale} #{type}: uploaded #{File.basename(file)}"
  end
end
