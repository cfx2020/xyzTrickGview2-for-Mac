// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "XYZMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "XYZMonitor",
            targets: ["XYZMonitor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "XYZMonitor",
            dependencies: [],
            path: "XYZMonitor/Sources"
        ),
        .testTarget(
            name: "XYZMonitorTests",
            dependencies: ["XYZMonitor"],
            path: "XYZMonitor/Tests"
        )
    ]
)
