// Frames raw App Store screenshots with a Russian benefit headline
// (app-store-presence). The canvas keeps the raw pixel size, so App Store size
// classes (iPhone 6.9" 1320×2868, iPad 13" 2752×2064) are preserved.
//
// Usage: swift tools/frame_screenshots.swift [RAW_DIR] [OUT_ROOT] [LOCALE ...]
//   defaults: fastlane/screenshots_raw/ru  fastlane/screenshots  ru es-ES es-MX
// Raw files are "<device>-<scene>.png" (fastlane snapshot); headlines come from
// fastlane/screenshot_headlines.json keyed by scene. Existing PNGs in each
// locale directory are replaced.
import AppKit

let args = Array(CommandLine.arguments.dropFirst())
let rawDir = URL(fileURLWithPath: args.count > 0 ? args[0] : "fastlane/screenshots_raw/ru")
let outRoot = URL(fileURLWithPath: args.count > 1 ? args[1] : "fastlane/screenshots")
let locales = args.count > 2 ? Array(args[2...]) : ["ru", "es-ES", "es-MX"]
let headlinesURL = URL(fileURLWithPath: "fastlane/screenshot_headlines.json")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

func color(_ hex: Int) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}
// Plumaje tokens (DesignSystem/Tokens/LoritoColor.swift, light): ink, onInk, accent.
let background = color(0x0F1A14)
let headlineColor = color(0xF3F4EF)
let accent = color(0x0E7C47)

guard let data = try? Data(contentsOf: headlinesURL),
      let headlines = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
    fail("cannot read \(headlinesURL.path)")
}
let raws = ((try? FileManager.default.contentsOfDirectory(at: rawDir, includingPropertiesForKeys: nil)) ?? [])
    .filter { $0.pathExtension == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
guard !raws.isEmpty else { fail("no raw screenshots in \(rawDir.path)") }

func frame(_ url: URL, headline: String) -> Data? {
    guard let image = NSImage(contentsOf: url),
          let rep = image.representations.first else { return nil }
    let w = CGFloat(rep.pixelsWide), h = CGFloat(rep.pixelsHigh)
    guard let canvas = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w), pixelsHigh: Int(h),
                                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
    canvas.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)
    background.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    let landscape = w > h
    let band = h * (landscape ? 0.17 : 0.16)              // headline band at the top
    let margin = min(w, h) * 0.06

    // Headline, centred, up to two lines.
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineBreakMode = .byWordWrapping
    let fontSize = min(w, h) * (landscape ? 0.052 : 0.068)
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: headlineColor, .paragraphStyle: style]
    let text = NSAttributedString(string: headline, attributes: attrs)
    let textRect = NSRect(x: margin, y: h - band, width: w - 2 * margin, height: band - margin * 0.5)
    let bounds = text.boundingRect(with: textRect.size, options: [.usesLineFragmentOrigin])
    text.draw(with: NSRect(x: textRect.minX, y: textRect.minY + (textRect.height - bounds.height) / 2,
                           width: textRect.width, height: bounds.height), options: [.usesLineFragmentOrigin])

    // Accent rule under the headline.
    accent.setFill()
    NSBezierPath(roundedRect: NSRect(x: w / 2 - w * 0.05, y: h - band - margin * 0.15, width: w * 0.1,
                                     height: max(6, h * 0.004)), xRadius: 4, yRadius: 4).fill()

    // The screenshot, scaled into the remaining area with rounded corners.
    let available = NSRect(x: margin, y: margin * 0.6, width: w - 2 * margin, height: h - band - margin * 1.2)
    let scale = min(available.width / w, available.height / h)
    let shot = NSRect(x: (w - w * scale) / 2, y: available.minY + (available.height - h * scale) / 2,
                      width: w * scale, height: h * scale)
    let radius = min(shot.width, shot.height) * 0.06
    NSGraphicsContext.current?.saveGraphicsState()
    NSBezierPath(roundedRect: shot, xRadius: radius, yRadius: radius).addClip()
    image.draw(in: shot, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.restoreGraphicsState()
    NSGraphicsContext.restoreGraphicsState()
    return canvas.representation(using: .png, properties: [:])
}

let fm = FileManager.default
for locale in locales {
    let dir = outRoot.appendingPathComponent(locale)
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    for old in (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [] where old.pathExtension == "png" {
        try? fm.removeItem(at: old)
    }
}
var count = 0
for raw in raws {
    let name = raw.deletingPathExtension().lastPathComponent
    guard let scene = name.split(separator: "-").last.map(String.init), let headline = headlines[scene] else {
        fail("no headline for \(raw.lastPathComponent)")
    }
    guard let png = frame(raw, headline: headline) else { fail("cannot frame \(raw.lastPathComponent)") }
    for locale in locales {
        try png.write(to: outRoot.appendingPathComponent(locale).appendingPathComponent(raw.lastPathComponent))
    }
    count += 1
}
print("framed \(count) screenshot(s) into \(locales.joined(separator: ", "))")
