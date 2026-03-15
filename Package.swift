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
        .library(name: "ReaderEither", targets: ["ReaderEither"]),
        .library(name: "ReaderEitherOperators", targets: ["ReaderEitherOperators"])
    ],
    targets: [
        .target(name: "FP"),
        .target(name: "Either", dependencies: ["FP"]),
        .target(name: "Reader", dependencies: ["FP"]),
        .target(name: "Operators", dependencies: ["FP"]),
        .target(name: "EitherOperators", dependencies: ["Either", "Operators"]),
        .target(name: "ReaderOperators", dependencies: ["Reader", "Operators"]),
        .target(name: "ReaderEither", dependencies: ["Reader", "Either"]),
        .target(name: "ReaderEitherOperators", dependencies: ["ReaderEither", "Reader", "Either", "EitherOperators", "Operators"]),
        .testTarget(name: "FPTests", dependencies: ["FP"]),
        .testTarget(name: "EitherTests", dependencies: ["Either", "FP"]),
        .testTarget(name: "ReaderTests", dependencies: ["Reader", "FP"]),
        .testTarget(name: "OperatorsTests", dependencies: ["Operators", "FP"]),
        .testTarget(name: "EitherOperatorsTests", dependencies: ["Either", "EitherOperators", "Operators", "FP"]),
        .testTarget(name: "ReaderOperatorsTests", dependencies: ["Reader", "ReaderOperators", "Operators", "FP"]),
        .testTarget(name: "ReaderEitherTests", dependencies: ["Reader", "Either", "ReaderEither", "FP"]),
        .testTarget(name: "ReaderEitherOperatorsTests", dependencies: ["Reader", "Either", "ReaderEither", "ReaderEitherOperators", "Operators", "EitherOperators", "FP"])
    ]
)
