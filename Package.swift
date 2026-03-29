// swift-tools-version: 6.2
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
        .library(name: "CoreFP", targets: ["CoreFP"]),
        .library(name: "CoreFPOperators", targets: ["CoreFPOperators"]),
        .library(name: "DataStructure", targets: ["DataStructure"]),
        .library(name: "DataStructureOperators", targets: ["DataStructureOperators"])
    ],
    targets: [
        .target(name: "CoreFP"),
        .target(name: "CoreFPOperators", dependencies: ["CoreFP"]),
        .target(name: "DataStructure", dependencies: ["CoreFP"]),
        .target(name: "DataStructureOperators", dependencies: ["DataStructure", "CoreFPOperators"]),
        .target(name: "FP", dependencies: ["CoreFP", "CoreFPOperators", "DataStructure", "DataStructureOperators"]),
        .testTarget(name: "CoreFPTests", dependencies: ["CoreFP"]),
        .testTarget(name: "CoreFPOperatorsTests", dependencies: ["CoreFPOperators", "CoreFP"]),
        .testTarget(name: "DataStructureTests", dependencies: ["DataStructure", "CoreFP"]),
        .testTarget(name: "DataStructureOperatorsTests", dependencies: ["DataStructure", "DataStructureOperators", "CoreFPOperators", "CoreFP"])
    ]
)
