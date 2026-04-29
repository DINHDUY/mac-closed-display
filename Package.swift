// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClosedDisplay",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClosedDisplay", targets: ["ClosedDisplay"]),
        .executable(name: "ClosedDisplayHelper", targets: ["ClosedDisplayHelper"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ClosedDisplay",
            dependencies: [],
            path: "src",
            exclude: ["Helper"]
        ),
        .executableTarget(
            name: "ClosedDisplayHelper",
            dependencies: [],
            path: "src/Helper"
        ),
        .testTarget(
            name: "ClosedDisplayTests",
            dependencies: ["ClosedDisplay"],
            path: "tests"
        ),
    ]
)
