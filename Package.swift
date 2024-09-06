// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FP",
    products: [
        .library(name: "FP", targets: ["FP"]),
        .library(name: "Either", targets: ["FP"]),
        .library(name: "Operators", targets: ["Operators"])
    ],
    targets: [
        .target(name: "FP"),
        .target(name: "Either", dependencies: ["FP"]),
        .target(name: "Operators", dependencies: ["FP"]),
        .testTarget(name: "FPTests", dependencies: ["FP"]),
        .testTarget(name: "EitherTests", dependencies: ["Either"]),
        .testTarget(name: "OperatorsTests", dependencies: ["Operators"])
    ]
)
