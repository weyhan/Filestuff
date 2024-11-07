// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Filestuff",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        ],
    products: [
        .library(
            name: "Filestuff",
            targets: ["Filestuff"]
        ),
    ],
    targets: [
        .target(
            name: "Filestuff",
            path: "Filestuff"
        ),
        .testTarget(
            name: "FilestuffTests",
            dependencies: ["Filestuff"],
            path: "FilestuffTests"
        ),
    ]
)
