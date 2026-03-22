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
        .library(name: "Core", targets: ["Core"]),
        .library(name: "CoreOperators", targets: ["CoreOperators"]),
        .library(name: "DataStructure", targets: ["DataStructure"]),
        .library(name: "DataStructureOperators", targets: ["DataStructureOperators"])
    ],
    targets: [
        .target(name: "Core"),
        .target(name: "CoreOperators", dependencies: ["Core"]),
        .target(name: "DataStructure", dependencies: ["Core"]),
        .target(name: "DataStructureOperators", dependencies: ["DataStructure", "CoreOperators"]),
        .target(name: "FP", dependencies: ["Core", "CoreOperators", "DataStructure", "DataStructureOperators"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "CoreOperatorsTests", dependencies: ["CoreOperators", "Core"]),
        .testTarget(name: "DataStructureTests", dependencies: ["DataStructure", "Core"]),
        .testTarget(name: "DataStructureOperatorsTests", dependencies: ["DataStructure", "DataStructureOperators", "CoreOperators", "Core"])
    ]
)
