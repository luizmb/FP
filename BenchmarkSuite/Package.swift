// swift-tools-version: 6.2
import PackageDescription

// Benchmarks live in a nested package so the published FP library never gains a
// dependency on package-benchmark (or its jemalloc system requirement). It
// references the root package by path and is built/run only by a dedicated,
// non-gating CI benchmark job.
let package = Package(
    name: "FPBenchmarks",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.4.0")
    ],
    targets: [
        .executableTarget(
            name: "IdentifiedArrayBenchmarks",
            dependencies: [
                .product(name: "DataStructure", package: "FP"),
                .product(name: "CoreFP", package: "FP"),
                .product(name: "Benchmark", package: "package-benchmark")
            ],
            path: "Benchmarks/IdentifiedArrayBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        )
    ]
)
