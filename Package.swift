// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport

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
        .library(name: "DataStructureOperators", targets: ["DataStructureOperators"]),
        .library(name: "FPMacros", targets: ["FPMacros"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.1"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        .target(name: "CoreFP"),
        .target(name: "CoreFPOperators", dependencies: ["CoreFP"]),
        .target(name: "DataStructure", dependencies: ["CoreFP"]),
        .target(name: "DataStructureOperators", dependencies: ["DataStructure", "CoreFPOperators"]),
        .target(name: "FP", dependencies: ["CoreFP", "CoreFPOperators", "DataStructure", "DataStructureOperators"]),
        .macro(
            name: "FPMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "FPMacros",
            dependencies: [
                "CoreFP",
                "FPMacrosPlugin"
            ]
        ),
        .testTarget(name: "CoreFPTests", dependencies: ["CoreFP"]),
        .testTarget(name: "CoreFPOperatorsTests", dependencies: ["CoreFPOperators", "CoreFP"]),
        .testTarget(name: "DataStructureTests", dependencies: ["DataStructure", "CoreFP"]),
        .testTarget(name: "DataStructureOperatorsTests", dependencies: ["DataStructure", "DataStructureOperators", "CoreFPOperators", "CoreFP"]),
        .testTarget(
            name: "FPMacrosTests",
            dependencies: [
                "FPMacros",
                "CoreFP",
                "CoreFPOperators",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)
