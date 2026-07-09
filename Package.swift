// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LaunchNotes",
    platforms: [
        // SwiftUI presentation, verified on iOS (the app) and macOS (the `swift build`/`swift test` host).
        // The default view is plain cross-platform SwiftUI, so watchOS/tvOS/visionOS can be added later
        // once their layouts are checked.
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "LaunchNotes", targets: ["LaunchNotes"])
    ],
    targets: [
        .target(name: "LaunchNotes"),
        .testTarget(
            name: "LaunchNotesTests",
            dependencies: ["LaunchNotes"]
        )
    ]
)
