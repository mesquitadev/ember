// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Ember",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Ember",
            path: "Sources/Ember",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
