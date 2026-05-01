// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Ln1",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Ln1", targets: ["Ln1"])
    ],
    targets: [
        .executableTarget(
            name: "Ln1",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AppKit")
            ]
        ),
        .testTarget(
            name: "Ln1Tests"
        )
    ]
)
