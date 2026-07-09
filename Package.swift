// swift-tools-version: 6.3
import CompilerPluginSupport
import PackageDescription

// swift-docc-plugin only generates documentation (run on macOS in CI via the Documentation
// workflow). Its command plugin is built by `swift build` on Windows and fails there, so exclude
// the dependency on Windows hosts — it is not needed to build or test the package.
var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.1"),
]
#if !os(Windows)
    dependencies.append(.package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"))
#endif

let package = Package(
    name: "FP",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "FP", targets: ["FP"]),
        .library(name: "CoreFP", targets: ["CoreFP"]),
        .library(name: "CoreFPOperators", targets: ["CoreFPOperators"]),
        .library(name: "DataStructure", targets: ["DataStructure"]),
        .library(name: "DataStructureOperators", targets: ["DataStructureOperators"]),
        .library(name: "FPMacros", targets: ["FPMacros"])
    ],
    dependencies: dependencies,
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
        .target(
            name: "FPMacrosExpander",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax")
            ]
        ),
        .executableTarget(
            name: "ExpandOptic",
            dependencies: [
                "FPMacrosExpander",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
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
