# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **`@Prisms` now generates one plain per-case property per case** (`shape.circle: Double?`,
  `loading.loaded: Success?`, etc.), typed `Payload?` and delegating to the `Prism` the macro
  already generates. Restores the ergonomics an earlier `@dynamicMemberLookup`-based design
  offered before it was removed (2026-06-17) for consistency between hand-written and
  macro-generated Prisms — but without reintroducing `@dynamicMemberLookup`: the macro can
  name every case explicitly at expansion time, so a named property per case is both simpler
  and more discoverable (autocomplete, no indirection through `PrismFocus`) than the
  dynamic-member subscript it replaces. Applied identically to the 5 hand-written Prism types
  (`Either`, `Loading`, `Validation`, `Optional`, `Result`) so macro and manual output stay in
  lockstep.
- Wired the previously-orphaned `ExpandOptic` executable target (and its `FPMacrosExpander`
  dependency) into `Package.swift` — both existed on disk and were referenced by
  `.swiftlint.yml`, but were never buildable via `swift build`/`swift run`. `swift run
  ExpandOptic <file.swift>` prints what `@Lenses`/`@Prisms` would generate for a
  shape-matching scratch declaration, for verifying the 5 hand-written Prism types stay in
  sync with the macro. See `CONTRIBUTING.md`.

### Fixed
- `Either`/`Validation`/`Loading`'s doc comments, and a whole README `@Prisms` section, still
  described the removed `@dynamicMemberLookup` per-case-accessor design (and a `.properties`
  `PrismsOptions` case that was never actually implemented) — both now describe the real,
  current per-case-property behavior.

## [2.0.0] - 2026-07-08

A comprehensive gap-and-consistency audit of the whole library: every type family now has
symmetric operator coverage, the transformer matrix is complete, the `Validation` Monad
instances that violated the Applicative/Monad consistency law are gone, and the DocC catalog
gained 10 new articles, a Haskell-mapping section on every article, and its first interactive
tutorial. See the migration notes below for the breaking changes.

### Breaking Changes
- Removed the four `Validation`-as-inner Monad instances — `EitherTValidation`,
  `ReaderTValidation`, `StatefulTValidation`, `WriterTValidation` no longer expose
  `flatMapT`/`bindT` or the `>>-`/`-<<`/`>=>`/`<=<` operators. Each combo's `flatMapT`
  short-circuited on the first `Validation` failure while its `liftA2T` accumulated errors,
  violating the Monad/Applicative consistency law. `Validation` is now Applicative-only in
  both directions (as it already was when Validation is the outer type). Convert via
  `.toEither()` first if you need short-circuit sequencing.
- Renamed 10 `fmapTValidationX` free functions to `mapTValidationX` (`Array`, `Either`,
  `NonEmpty`, `Optional`, `Reader`, `Result`, `Stateful`, `Writer`), matching the `mapT`
  naming convention used by every other transformer combo.
- Removed the undocumented `<<=` Reader comonad-extend operator (an alias for `extend` that
  overloaded the standard library's compound-assignment operator). Use `->>`/`<<-`, which
  already cover comonad extend in both directions.
- Removed 6 stray `<&>` overloads on `ReaderT*+MonadOperators` (Array/Either/Optional/
  Publisher/Reader/Result) that duplicated `<&^>` from the sibling `+FunctorOperators` files.

### Added
- **New types**: `These<A, B>` (Haskell's inclusive-or sum type — `.this`/`.that`/`.both`,
  with a real Applicative *and* Monad instance requiring `A: Semigroup`) and `Zipper<A>`
  (the classic focused list zipper, with a lawful Comonad instance requiring no constraint).
- **`Result`**: `traverse`/`sequence` into `Array`/`Optional`/`Either`/`Validation`, and
  `fold(onSuccess:onFailure:)` — closing the biggest single-type gap the audit found.
- **`NonEmpty`**: a full Comonad instance (`extract`/`extend`/`duplicate`), and a complete
  Applicative + Monad-operator surface across all 8 transformer combos (`EitherTNonEmpty`,
  `NonEmptyTEither`, `NonEmptyTOptional`, `OptionalTNonEmpty`, `NonEmptyTResult`,
  `ReaderTNonEmpty`, `StatefulTNonEmpty`, `WriterTNonEmpty`) plus `ValidationTNonEmpty`
  — previously only Functor + Monad (or Functor only) existed, with no Applicative anywhere
  and, for `OptionalTNonEmpty`, no operators at all.
- **Monoid wrappers**: `Min`/`Max`/`First`/`Last` (Semigroup-only — no identity exists for
  an arbitrary type), `Dual` (Semigroup always, Monoid when the wrapped type is), and
  `Ordering` (wraps `ComparisonResult` for composable lexicographic comparators via
  `mconcat`, plus a `comparing(_:)` key-extractor helper).
- **`Writer`** gains Semigroup/Monoid conformance (combines `value` and `log` pointwise).
- **`Loading`** gains a full Applicative (`apply`/`liftA2`/`seqRight`/`seqLeft`) plus
  `zip3`/`zip4`, built from the existing `zip` and preserving its
  `.failed > .idle > .loading > .loaded` precedence.
- **`zip3`/`zip4`** for `Array`. (`Optional`/`Result`/`Either` already had fully-variadic
  `zip` via parameter packs, which subsumes arbitrary arities — no change needed there.)
- **`pure`** named function on `Optional`/`Result`/`Array`/`Either`, matching the existing
  `Reader`/`NonEmpty` precedent, for point-free parity.
- Named `kleisliT` free functions everywhere `>=>`/`<=<` previously inlined
  `{ a in fn1(a).flatMapT(fn2) }`, so every Kleisli operator now delegates to a named
  function per the library's operator-delegation rule.
- The 4 missing `<=<` overloads for `ArrayTOptional`/`ArrayTResult`/`OptionalTArray`/
  `OptionalTResult`.
- Test coverage for every transformer stack that had none in either the core or operator
  target: the Reader-outer combos, the Validation-outer combos, the Combine/Publisher
  stacks, and the 4 CoreFP combos above.
- **10 new DocC articles**: Optics, Semigroup & Monoid, Monad Transformers, Operator
  Vocabulary & Precedence, Point-Free Style, Newtype, Gen, Macros, SumType2, Endo/EndoMut.
- A "For Haskell developers" section — with a type/operator mapping table and curated
  external references — added to all 14 pre-existing DocC articles.
- The library's first DocC Tutorial: "Modeling Failures: Optional → Result → Either →
  Validation," a 4-section interactive walkthrough.
- README: a Quick Start section, an operator precedence table, a "Coming from Haskell"
  migration table, documentation for all 6 macros (previously 2 of 6), and new Newtype/Gen
  sections.

### Fixed
- The `SumType2` protocol's doc comment (and the README) had an inverted left/right case
  table for `Result`/`Optional` — `Result.success`/`Optional.some` are the *left*/`A` case,
  not the right/`B` case as previously documented — and both wrongly listed `Validation` as
  conforming to `SumType2`, which it doesn't.
- A pre-existing unterminated code fence in the README that broke its GitHub rendering from
  partway through the file onward.
- `StatefulTNonEmpty`'s `>=>`/`<=<`/`kleisliT` had an asymmetric signature (a non-optional
  first arrow where its `EitherTNonEmpty`/`ReaderTNonEmpty`/`WriterTNonEmpty` siblings all
  use a symmetric optional-returning shape), which would have silently broken on any
  3-arrow Kleisli chain. Fixed to match its siblings.
- Inline `///` documentation raised on the primary type-definition files for `Either`,
  `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, and `NonEmpty`.

### Removed
- `IMPLEMENTATION_SUMMARY.md` and `PRECEDENCE_CORRECTIONS.md` — internal, stale working
  documents whose accurate content (operator vocabulary, precedence tables, the transformer
  coverage matrix) has been rescued into the new `OperatorVocabulary` and `MonadTransformers`
  DocC articles, re-verified against the current source rather than copied as-is.

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
