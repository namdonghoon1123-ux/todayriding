// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TodayRiding",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "TodayRidingCore", targets: ["TodayRidingCore"]),
        .executable(name: "TodayRidingValidation", targets: ["TodayRidingValidation"])
    ],
    targets: [
        .target(name: "TodayRidingCore"),
        .executableTarget(
            name: "TodayRidingValidation",
            dependencies: ["TodayRidingCore"]
        )
    ]
)
