// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "03",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "03", targets: ["ZeroThree"])
    ],
    targets: [
        .executableTarget(
            name: "ZeroThree",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AppKit")
            ]
        ),
        .testTarget(
            name: "ZeroThreeTests"
        )
    ]
)
