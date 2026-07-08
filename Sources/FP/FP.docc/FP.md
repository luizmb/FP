# ``FP``

A pure, Haskell-inspired functional programming toolkit for Swift — optics, algebraic
types, effects, and a full suite of composition operators.

## Overview

`FP` is an umbrella module that re-exports four focused libraries. Import `FP` for everything,
or import exactly the piece you need — each has its own documentation landing page, reachable
via the module switcher in the sidebar:

| Module | Contents |
|--------|----------|
| `CoreFP` | Optics (Lens, Prism, AffineTraversal, Iso), the Semigroup/Monoid hierarchy, standard-library extensions, the `SumType2` protocol |
| `CoreFPOperators` | Operator syntax for `CoreFP`: `>>>`, `<<<`, `\|>`, `£`, `<\|>`, `<£>`, `<*>`, `>>-`, `>=>`, `<=<`, … |
| `DataStructure` | The library's own algebraic and effect types: `Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `NonEmpty`, `IdentifiedArray`, `Loading`, `These`, `Zipper`, `Newtype`, `Gen` |
| `DataStructureOperators` | Operator syntax for `DataStructure` |

Everything is pure: no implicit side effects, no singletons, `Sendable`-first, errors modelled as
values (`Result` / `Either` / `Validation`) rather than `throws`, and async modelled lazily.

```swift
import FP

let parsed = "42"
    |> Int.init                 // Optional<Int>
    <£> { $0 * 2 }              // functor map → Optional<Int>
    ?? 0                        // 84
```

## Topics

### Tutorials
- <doc:FPTutorials>

### Code Generation
- <doc:Macros>

### Concepts
- <doc:MonadTransformers>
- <doc:OperatorVocabulary>
