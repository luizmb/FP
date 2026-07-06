# ``FP``

A pure, Haskell-inspired functional programming toolkit for Swift — optics, algebraic
types, effects, and a full suite of composition operators.

## Overview

`FP` is an umbrella module that re-exports four focused libraries. Import `FP` for everything,
or import exactly the piece you need:

| Module | Contents |
|--------|----------|
| `CoreFP` | Optics (Lens, Prism, AffineTraversal, Iso), the Semigroup/Monoid hierarchy, free functions, the SumType protocol |
| `CoreFPOperators` | The operator surface: `>>>`, `<<<`, `|>`, `£`, `<|>`, `<£>`, `<*>`, `>>-`, `>=>`, `<=<`, … |
| `DataStructure` | Algebraic and effect types: `Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `NonEmpty`, `IdentifiedArray`, `Loading` |
| `DataStructureOperators` | Operator variants for the data-structure types |

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

### Error Handling & Sum Types
- <doc:Either>
- <doc:Result>
- <doc:Optional>
- <doc:Validation>

### Collections & Sequences
- <doc:Array>
- <doc:NonEmpty>
- <doc:IdentifiedArray>
- <doc:AsyncSequence>
- <doc:Publisher>

### Effects & State
- <doc:Reader>
- <doc:Writer>
- <doc:Stateful>
- <doc:Loading>

### SwiftUI Interop
- <doc:Binding>
