# ``FP``

A pure, Haskell-inspired functional programming toolkit for Swift — optics, algebraic
types, effects, and a full suite of composition operators.

## Overview

`FP` is an umbrella module that re-exports four focused libraries. Import `FP` for everything,
or import exactly the piece you need — each has its own documentation landing page:

| Module | Contents |
|--------|----------|
| [CoreFP](../corefp) | Optics (Lens, Prism, AffineTraversal, Iso), the Semigroup/Monoid hierarchy, standard-library extensions, the `SumType2` protocol, `TransformerStack`/`MonadT` and the stacks built only from `Array`/`Optional`/`Result`/`AsyncStream`/`Publisher` (`OptionalTArray`, `PublisherTResult`, …) |
| [CoreFPOperators](../corefpoperators) | Operator syntax for `CoreFP`: `>>>`, `<<<`, `\|>`, `<\|`, `<\|>`, `<£>`, `<*>`, `>>-`, `>=>`, `<=<`, … |
| [DataStructure](../datastructure) | The library's own algebraic and effect types: `Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `NonEmpty`, `IdentifiedArray`, `Loading`, `These`, `Zipper`, `Newtype`, `Gen`, and every transformer stack with a DataStructure layer (`ReaderTEither`, `StatefulTWriter`, …) |
| [DataStructureOperators](../datastructureoperators) | Operator syntax for `DataStructure` |
| `FPMacros` (separate product, not re-exported by `FP`; `import FPMacros`) | `@Lenses`, `@Prisms`, `@ApplyOptics`/`@NoOptics`, `@Iso`, `@DeriveMonoid`, `@Mock`, `@Witness` |

Everything is pure: no implicit side effects, no singletons, `Sendable`-first, errors modelled as
values (`Result` / `Either` / `Validation`) rather than `throws`. The Combine `Publisher` and `AsyncStream`
extensions are a deliberate exception (eager, Apple and Concurrency-runtime types, guarded by `#if canImport`),
and their monads follow Haskell stream semantics: bind is ordered concat and `<*>` is `ap`.

Haskell is the source of truth for the semantics. A monad surface exists only where `transformers`
defines one, `<*>` is `ap` wherever there is a monad, bind takes a continuation over the full stack,
and the Compose-style (zip) applicative is a separate named function, never the operator.

```swift
import FP

let parsed = ({ $0 * 2 } <£> Int("42")) ?? 0   // 84
```

## Topics

### Tutorials
- <doc:FPTutorials>

### Code Generation
- <doc:Macros>

### Upgrading
- <doc:Migrating3>

### Concepts
- <doc:MonadTransformers>
- <doc:OperatorVocabulary>
