// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "duo_kit",
    platforms: [
        // Xcode 27 rejects lower deployment targets.
        .iOS("15.0")
    ],
    products: [
        .library(name: "duo-kit", targets: ["duo_kit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "duo_kit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
