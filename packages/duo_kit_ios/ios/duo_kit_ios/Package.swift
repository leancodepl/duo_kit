// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "duo_kit_ios",
    platforms: [
        // Xcode 27 rejects lower deployment targets.
        .iOS("15.0")
    ],
    products: [
        .library(name: "duo-kit-ios", targets: ["duo_kit_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "duo_kit_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
