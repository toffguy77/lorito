// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LoritoKit",
    // macOS is included so the pure Domain layer (and other host-safe layers)
    // can be unit-tested from the command line via `swift test`.
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Content", targets: ["Content"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Features", targets: ["Features"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
    ],
    targets: [
        // Pure Swift. MUST NOT import SwiftUI, SwiftData, or CloudKit.
        .target(name: "Domain"),

        // Loads the compiled content bundle and exposes it via Domain model types.
        .target(
            name: "Content",
            dependencies: ["Domain"],
            resources: [.process("Resources")]
        ),

        // SwiftData + CloudKit user-data store.
        .target(name: "Persistence", dependencies: ["Domain"]),

        // "Modern Calm" design tokens and reusable SwiftUI components.
        .target(
            name: "DesignSystem",
            dependencies: [.product(name: "MarkdownUI", package: "swift-markdown-ui")]
        ),

        // SwiftUI screens. Depends inward on every other layer.
        .target(
            name: "Features",
            dependencies: ["Domain", "Content", "Persistence", "DesignSystem"]
        ),

        // Tests
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "ContentTests", dependencies: ["Content"]),
        .testTarget(name: "FeaturesTests", dependencies: ["Features"]),
    ]
)
