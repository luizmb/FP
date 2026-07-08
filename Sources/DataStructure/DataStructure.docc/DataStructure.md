# ``DataStructure``

The library's own algebraic and effect types: sum types, monad transformers, and the property-based-testing generator.

## Overview

`DataStructure` is where the library's actual named types live — as opposed to `CoreFP`, which extends types you don't own (`Optional`, `Result`, `Array`, `Combine.Publisher`) and provides the optics/algebra foundation everything else builds on.

```swift
import DataStructure

let parsed: Either<String, Int> = Int("42").map(Either.right) ?? .left("not a number")
```

Import `DataStructureOperators` alongside this module for the operator syntax (`<£>`, `<*>`, `>>-`, `>=>`, …) — the full precedence table is in the "OperatorVocabulary" article, in the `FP` module's documentation (use the module switcher in the sidebar). The `OuterTInner` monad-transformer naming convention this module follows throughout is explained in the "MonadTransformers" article, also in `FP`'s documentation.

## Topics

### Error Handling & Sum Types
- ``Either``
- ``Validation``
- ``These``

### Collections & Sequences
- ``NonEmpty``
- ``Zipper``
- ``IdentifiedArray``

### Effects & State
- ``Reader``
- ``Writer``
- ``Stateful``
- ``Loading``

### Foundations
- ``Newtype``
- ``Gen``
