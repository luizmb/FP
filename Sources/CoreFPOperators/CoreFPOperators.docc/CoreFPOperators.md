# ``CoreFPOperators``

The operator syntax for everything in `CoreFP` — Functor/Applicative/Monad operators for `Optional`, `Result`, `Array`, `Combine.Publisher`, `AsyncSequence`, and function composition (`>>>`, `<<<`, `|>`, `£`).

## Overview

Every operator here delegates to a named function in [CoreFP](../corefp) — the operator module never implements logic itself, only syntax. Import both modules together (or the [FP](../fp) umbrella, which re-exports everything):

```swift
import CoreFP
import CoreFPOperators

let result = { $0 * 2 } <£> Optional(5)   // Optional(10)
```

The full, verified operator/precedence table across both `CoreFPOperators` and `DataStructureOperators` lives in [OperatorVocabulary](../fp/operatorvocabulary).

Every operator here is heavily overloaded — one per type it applies to (`Optional`, `Result`, `Array`, `Publisher`, `AsyncSequence`, and every transformer combo between them) — so browse them via the automatically-generated **Operators** section below rather than a hand-curated list here, to avoid linking to the wrong overload.

## Related Modules

| Module | Contents |
|--------|----------|
| [FP (umbrella)](../fp) | Re-exports all four modules; also the home of cross-cutting conceptual articles |
| [CoreFP](../corefp) | Named functions this module's operators delegate to |
| [DataStructure](../datastructure) | The library's own algebraic and effect types |
| [DataStructureOperators](../datastructureoperators) | Operator syntax for `DataStructure` |
