// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Sandbox",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "Sandbox",
            dependencies: [.product(name: "FP", package: "FP")],
            path: "Sources"
        )
    ]
)
