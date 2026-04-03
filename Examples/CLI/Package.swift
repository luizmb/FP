// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CLI",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "CLI",
            dependencies: [.product(name: "FP", package: "FP")],
        )
    ],
    swiftLanguageModes: [.v6]
)
