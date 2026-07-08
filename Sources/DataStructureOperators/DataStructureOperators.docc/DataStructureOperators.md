# ``DataStructureOperators``

The operator syntax for everything in `DataStructure` — Functor/Applicative/Monad operators for `Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, `NonEmpty`, `These`, `Zipper`, plus every `OuterTInner` transformer combo between them.

## Overview

Every operator here delegates to a named function in [DataStructure](../datastructure) — the operator module never implements logic itself, only syntax. Import both modules together (or the [FP](../fp) umbrella, which re-exports everything):

```swift
import DataStructure
import DataStructureOperators

let parsed = Either<String, Int>.right(5) >>- { n in n > 0 ? .right(n) : .left("negative") }
```

The full, verified operator/precedence table across both `CoreFPOperators` and `DataStructureOperators` lives in [OperatorVocabulary](../fp/operatorvocabulary).

Every operator here is heavily overloaded — one per type it applies to (`Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, `NonEmpty`, `These`, `Zipper`, and every transformer combo between them) — so browse them via the automatically-generated **Operators** section below rather than a hand-curated list here, to avoid linking to the wrong overload.

## Related Modules

| Module | Contents |
|--------|----------|
| [FP (umbrella)](../fp) | Re-exports all four modules; also the home of cross-cutting conceptual articles |
| [CoreFP](../corefp) | Optics, Semigroup/Monoid, standard-library extensions |
| [CoreFPOperators](../corefpoperators) | Operator syntax for `CoreFP` |
| [DataStructure](../datastructure) | Named functions this module's operators delegate to |
