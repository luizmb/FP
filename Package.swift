// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FP",
    products: [
        .library(name: "FP", targets: ["FP"]),
        .library(name: "CombineFP", targets: ["CombineFP"]),
        .library(name: "Either", targets: ["FP"]),
        .library(name: "Reader", targets: ["Reader"]),
        .library(name: "Operators", targets: ["Operators"])
    ],
    targets: [
        .target(name: "FP"),
        .target(name: "CombineFP", dependencies: ["FP"]),
        .target(name: "Either", dependencies: ["FP"]),
        .target(name: "Reader", dependencies: ["FP"]),
        .target(name: "Operators", dependencies: ["FP"]),
        .testTarget(name: "FPTests", dependencies: ["FP"]),
        .testTarget(name: "CombineFPTests", dependencies: ["CombineFP", "Operators", "FP"]),
        .testTarget(name: "EitherTests", dependencies: ["Either", "Operators", "FP"]),
        .testTarget(name: "ReaderTests", dependencies: ["Reader", "Operators", "FP"]),
        .testTarget(name: "OperatorsTests", dependencies: ["Operators"])
    ]
)
