# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.13.0] - 2026-07-03

### Added
- `IdentifiedArray` — ordered, O(1) by-id collection with optics (`ix(id:)`, `traversed`, dedup prism) (#71).
- `@Lenses`-generated initialisers now default optional parameters to `nil`.

### Changed
- Performance: `IdentifiedArray` construction is `@inlinable` with `reserveCapacity` + unsafe-buffer reindex, fixing O(n) build allocations.
- Whole codebase reformatted under SwiftFormat and brought to SwiftLint strict — 0 violations.

## [1.12.0] - 2026-06-17

### Added
- `Monoid` `mconcat` / `sconcat` are now customization points.
- Windows build + test CI job; RC stage now also tests Android and Windows.

### Changed
- Performance: `Monoid` `Array`/`String` folds are pre-sized single passes.

## [1.11.0] - 2026-06-17

### Added
- Android build + emulator test CI job.

### Changed
- `@Prisms` no longer emits the per-case `.properties` output; manual `Prism` types aligned with macro output.

### Fixed
- Guarded `Float80` conformance against Windows and Android.

## [1.10.0] - 2026-06-15

- See the [GitHub release notes](https://github.com/luizmb/FP/releases) for details on 1.10.0 and earlier.

[Unreleased]: https://github.com/luizmb/FP/compare/v1.13.0...main
[1.13.0]: https://github.com/luizmb/FP/compare/v1.12.0...v1.13.0
[1.12.0]: https://github.com/luizmb/FP/compare/v1.11.0...v1.12.0
[1.11.0]: https://github.com/luizmb/FP/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/luizmb/FP/releases/tag/v1.10.0
