// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickPad",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "QuickPad", targets: ["QuickPad"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "QuickPad",
            dependencies: [],
            path: "Sources/QuickPad"
        )
    ]
)
