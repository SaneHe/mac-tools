// swift-tools-version: 5.8
import PackageDescription

// The package keeps core detection/transform logic isolated from the macOS UI scaffold.
let package = Package(
    name: "MacTextActions",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MacTextActionsCore",
            targets: ["MacTextActionsCore"]
        ),
        .executable(
            name: "MacTextActionsApp",
            targets: ["MacTextActionsApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1")
    ],
    targets: [
        .target(
            name: "MacTextActionsCore"
        ),
        .executableTarget(
            name: "MacTextActionsApp",
            dependencies: [
                "MacTextActionsCore",
                "HotKey"
            ]
        ),
        .testTarget(
            name: "MacTextActionsCoreTests",
            dependencies: ["MacTextActionsCore"]
        ),
        .testTarget(
            name: "MacTextActionsAppTests",
            dependencies: ["MacTextActionsApp", "MacTextActionsCore"]
        )
    ]
)
