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
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1"),
        .package(url: "https://github.com/jaywcjlove/PermissionFlow.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MacTextActionsCore"
        ),
        .executableTarget(
            name: "MacTextActionsApp",
            dependencies: [
                "MacTextActionsCore",
                "HotKey",
                .product(name: "PermissionFlow", package: "PermissionFlow")
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
