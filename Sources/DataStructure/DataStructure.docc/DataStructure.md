# ``DataStructure``

The library's own algebraic and effect types: sum types, monad transformers, and the property-based-testing generator.

## Overview

`DataStructure` is where the library's actual named types live — as opposed to [CoreFP](../corefp), which extends types you don't own (`Optional`, `Result`, `Array`, `Combine.Publisher`) and provides the optics/algebra foundation everything else builds on.

```swift
import DataStructure

let parsed: Either<String, Int> = Int("42").map(Either.right) ?? .left("not a number")
```

Import [DataStructureOperators](../datastructureoperators) alongside this module for the operator syntax (`<£>`, `<*>`, `>>-`, `>=>`, …) — the full precedence table is in [OperatorVocabulary](../fp/operatorvocabulary). The `OuterTInner` monad-transformer naming convention this module follows throughout is explained in [MonadTransformers](../fp/monadtransformers).

## Related Modules

| Module | Contents |
|--------|----------|
| [FP (umbrella)](../fp) | Re-exports all four modules; also the home of cross-cutting conceptual articles |
| [CoreFP](../corefp) | Optics, Semigroup/Monoid, standard-library extensions |
| [CoreFPOperators](../corefpoperators) | Operator syntax for `CoreFP` |
| [DataStructureOperators](../datastructureoperators) | Operator syntax for this module |

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
