// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SessionHopper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SessionHopper", targets: ["SessionHopper"]),
        .library(name: "SessionHopperCore", targets: ["SessionHopperCore"])
    ],
    targets: [
        .target(name: "SessionHopperCore"),
        .executableTarget(
            name: "SessionHopper",
            dependencies: ["SessionHopperCore"]
        ),
        .testTarget(
            name: "SessionHopperCoreTests",
            dependencies: ["SessionHopperCore"]
        )
    ]
)
