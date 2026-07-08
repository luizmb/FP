# These

`These<A, B>` is the "inclusive-or" sum type: a value holds an `A` (`.this`), a `B` (`.that`), or **both at once** (`.both`). It fills a real gap between `Either` and `Validation`, neither of which can express "both sides present simultaneously."

```swift
import DataStructure

public enum These<A, B> {
    case this(A)
    case that(B)
    case both(A, B)
}
```

## Why not just use Either or Validation

| Type | Cases | Both sides at once? |
|---|---|---|
| `Either<A, B>` | `.left(A)`, `.right(B)` | No — exactly one side |
| `Validation<E, A>` | `.failure(E)`, `.success(A)` | No — exactly one side |
| `These<A, B>` | `.this(A)`, `.that(B)`, `.both(A, B)` | Yes — `.both` carries both |

`Either` and `Validation` both force a choice between exactly two outcomes. `These` is for the genuinely three-way case: aligning two lists of unequal length, merging two partial records by key, or accumulating a running log (`A`) alongside a final result (`B`) where the log is optional until the result also lands. Reach for `These` specifically when a computation can produce *both* halves, not just one or the other.

## Creating and consuming

```swift
let this: These<String, Int> = .this("only a")
let that: These<String, Int> = .that(42)
let both: These<String, Int> = .both("a", 42)

let result = both.match(
    caseThis: { "this: \($0)" },
    caseThat: { "that: \($0)" },
    caseBoth: { a, b in "both: \(a), \(b)" }
)
// "both: a, 42"
```

Convenience projections mirror `Either`'s `.a`/`.b`/`.isA`/`.isB`, but for three cases:

```swift
both.this     // Optional("a")  — present for .this and .both
both.that     // Optional(42)   — present for .that and .both
both.isBoth   // true
```

## Functor, Applicative, Monad

`These` is a `Functor` on `B` unconditionally. Its `Applicative` and `Monad` instances additionally require `A: Semigroup` — combining two `.both`/`.this` values has to *merge* their `A` payloads rather than arbitrarily pick one, exactly like `Validation`'s accumulating failure side:

```swift
let mapped: These<String, String> = that.map { String($0) }   // .that("42")

// Applicative / Monad require A: Semigroup (String, [String], …):
let both1: These<String, Int> = .both("log1: ", 10)
let both2: These<String, Int> = .both("log2: ", 5)
let combined = These<String, Int>.liftA2(+)(both1, both2)
// .both("log1: log2: ", 15)

let chained = both.flatMap { n in n > 0 ? .that(n) : .this("negative") }
```

Unlike `Validation`, `These` *does* have a lawful `Monad` instance — `flatMap` runs sequentially and merges any accumulated `A` payloads along the way via `Semigroup.combine`, rather than discarding one side:

```swift
// This <=< That  -> This a          (short-circuits, the a from the first is kept)
// That  <=< That  -> whatever the second returns
// Both  <=< Both  -> merges the accumulated `A`s via Semigroup, keeps the final `B`
```

## Interoperability

`These` bridges cleanly with `Either` and with pairs of optionals:

```swift
// Either has no "both" case — the conversion is always total and lossless
These<String, Int>.fromEither(.left("error"))   // .this("error")
These<String, Int>.fromEither(.right(42))        // .that(42)

// align: the "zip two optionals, keep whichever are present" operation
These<String, Int>.align("a", 1)     // .both("a", 1)
These<String, Int>.align("a", nil)   // .this("a")
These<String, Int>.align(nil, 1)     // .that(1)
These<String, Int>.align(nil, nil)   // nil — the only case with no `These` to build
```

`align` is the standard way to combine two independently-produced optional values into a single `These` — useful for merging two dictionaries by key, or zipping two arrays of unequal length element-by-element without truncating to the shorter one.

## Operators

| Operator | Requires | Behavior |
|---|---|---|
| `<£>` / `<&>` | — | Functor map over `B` |
| `£>` / `<£` | — | replace `B` with a constant, preserving whichever case was active |
| `<*>` | `A: Semigroup` | applicative apply |
| `*>` / `<*` | `A: Semigroup` | sequence, keeping right/left |
| `>>-` / `-<<` | `A: Semigroup` | monadic bind |
| `>=>` / `<=<` | `A: Semigroup` | Kleisli composition |

## For Haskell developers

`These<A, B>` is a direct port of the `these` package's `These a b`, down to the case names (`This`/`That`/`These` in Haskell become `.this`/`.that`/`.both` here, avoiding a clash with Swift's own `these` naming). The `align` function mirrors `Data.Align`'s class of the same name, whose core operation is exactly "zip two structures, but don't drop elements when they're different lengths."

| This library | Haskell parallel |
|---|---|
| `These<A, B>` | [`These a b`](https://hackage.haskell.org/package/these) (`these` package) |
| `.this` / `.that` / `.both` | `This` / `That` / `These` |
| `These.align(_:_:)` | [`Data.Align`](https://hackage.haskell.org/package/semialign)'s `align` (now in the `semialign` package) |
| `These.fromEither(_:)` | `these`'s `fromEither` |
| Applicative/Monad requiring `A: Semigroup` | same constraint on the `This`-side type in `these`'s own `Semigroup a => Applicative (These a)` instance |

**References:**
- [`Data.These`](https://hackage.haskell.org/package/these) — the `these` package, the canonical source for this type and its instances
- [`Data.Semialign`](https://hackage.haskell.org/package/semialign) — `align`/`Semialign`, the class this library's `align(_:_:)` static method is modeled after

- SeeAlso: `Either`, `Validation`, `Semigroup`
