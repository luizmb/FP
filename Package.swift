// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FP",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "FP", targets: ["FP"]),
        .library(name: "Either", targets: ["Either"]),
        .library(name: "Reader", targets: ["Reader"]),
        .library(name: "Operators", targets: ["Operators"]),
        .library(name: "EitherOperators", targets: ["EitherOperators"]),
        .library(name: "ReaderOperators", targets: ["ReaderOperators"]),
        .library(name: "CombineEither", targets: ["CombineEither"]),
        .library(name: "ReaderEither", targets: ["ReaderEither"]),
        .library(name: "ReaderEitherOperators", targets: ["ReaderEitherOperators"]),
        .library(name: "ReaderCombineFP", targets: ["ReaderCombineFP"]),
        .library(name: "ReaderCombineOperators", targets: ["ReaderCombineOperators"]),
        .library(name: "ReaderConcurrencyFP", targets: ["ReaderConcurrencyFP"]),
        .library(name: "ReaderConcurrencyOperators", targets: ["ReaderConcurrencyOperators"])
    ],
    targets: [
        .target(name: "FP"),
        .target(name: "Either", dependencies: ["FP"]),
        .target(name: "Reader", dependencies: ["FP"]),
        .target(name: "Operators", dependencies: ["FP"]),
        .target(name: "EitherOperators", dependencies: ["Either", "Operators"]),
        .target(name: "ReaderOperators", dependencies: ["Reader", "Operators"]),
        .target(name: "CombineEither", dependencies: ["FP", "Either"]),
        .target(name: "ReaderEither", dependencies: ["Reader", "Either"]),
        .target(name: "ReaderEitherOperators", dependencies: ["ReaderEither", "Reader", "Either", "EitherOperators", "Operators"]),
        .target(name: "ReaderCombineFP", dependencies: ["Reader", "FP"]),
        .target(name: "ReaderCombineOperators", dependencies: ["ReaderCombineFP", "Reader", "FP", "Operators"]),
        .target(name: "ReaderConcurrencyFP", dependencies: ["Reader", "FP"]),
        .target(name: "ReaderConcurrencyOperators", dependencies: ["ReaderConcurrencyFP", "Reader", "FP", "Operators"]),
        .testTarget(name: "FPTests", dependencies: ["FP"]),
        .testTarget(name: "EitherTests", dependencies: ["Either", "FP"]),
        .testTarget(name: "ReaderTests", dependencies: ["Reader", "FP"]),
        .testTarget(name: "OperatorsTests", dependencies: ["Operators", "FP"]),
        .testTarget(name: "EitherOperatorsTests", dependencies: ["Either", "EitherOperators", "Operators", "FP"]),
        .testTarget(name: "ReaderOperatorsTests", dependencies: ["Reader", "ReaderOperators", "Operators", "FP"]),
        .testTarget(name: "CombineEitherTests", dependencies: ["FP", "Either", "CombineEither"]),
        .testTarget(name: "ReaderEitherTests", dependencies: ["Reader", "Either", "ReaderEither", "FP"]),
        .testTarget(name: "ReaderEitherOperatorsTests", dependencies: ["Reader", "Either", "ReaderEither", "ReaderEitherOperators", "Operators", "EitherOperators", "FP"]),
        .testTarget(name: "ReaderCombineFPTests", dependencies: ["Reader", "FP", "ReaderCombineFP"]),
        .testTarget(name: "ReaderCombineOperatorsTests", dependencies: ["Reader", "FP", "ReaderCombineFP", "ReaderCombineOperators", "Operators"]),
        .testTarget(name: "ReaderConcurrencyFPTests", dependencies: ["Reader", "FP", "ReaderConcurrencyFP"]),
        .testTarget(name: "ReaderConcurrencyOperatorsTests", dependencies: ["Reader", "FP", "ReaderConcurrencyFP", "ReaderConcurrencyOperators", "Operators"])
    ]
)
