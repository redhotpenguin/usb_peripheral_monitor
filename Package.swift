// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "USBMonitor",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "USBMonitorCore", targets: ["USBMonitorCore"]),
        .executable(name: "USBMonitorDesktop", targets: ["USBMonitorDesktop"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.14.1"),
    ],
    targets: [
        .target(
            name: "USBMonitorCore",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            path: "Sources/USBMonitorCore",
            linkerSettings: [
                .linkedFramework("IOKit"),
            ]
        ),
        .executableTarget(
            name: "USBMonitorDesktop",
            dependencies: ["USBMonitorCore"],
            path: "Sources/USBMonitorDesktop"
        ),
    ]
)
