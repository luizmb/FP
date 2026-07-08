# ``SumType2``

`SumType2<A, B>` is the shared interface behind every built-in two-case sum type in this library — `Either`, `Result`, and `Optional` all conform. It gives you one `match` eliminator, one pair of optional projections (`.a` / `.b`), and one pair of predicates (`.isA` / `.isB`) that work identically no matter which concrete type you're holding.

```swift
import CoreFP

public protocol SumType2<A, B>: Sendable {
    associatedtype A
    associatedtype B

    static func left(_ a: A) -> Self
    static func right(_ b: B) -> Self

    func match<C>(caseLeft: (A) -> C, caseRight: (B) -> C) -> C
}
```

## Why write against `SumType2` instead of the concrete type

Without a shared interface, a function that needs to fold *any* two-case type into a result has to be duplicated once per type:

```swift
// Without SumType2 — one function per concrete type, identical shape
func summarizeEither(_ e: Either<String, Int>) -> String {
    e.match(caseLeft: { "error: \($0)" }, caseRight: { "value: \($0)" })
}
func summarizeResult(_ r: Result<Int, String>) -> String {
    r.match(caseLeft: { "value: \($0)" }, caseRight: { "error: \($0)" })
}
```

With `SumType2`, one generic function covers every conformer:

```swift
// With SumType2 — one function, any conforming type
func summarize<S: SumType2>(_ s: S) -> String where S.A: CustomStringConvertible, S.B: CustomStringConvertible {
    s.match(caseLeft: { "left: \($0)" }, caseRight: { "right: \($0)" })
}
```

This is the same motivation as Haskell's `Bifunctor`/`Bifoldable` typeclasses: write the traversal once, apply it to every two-case shape in scope.

## The full API

Every requirement beyond `match` is a protocol extension — free for any conformer:

| Member | Kind | Behavior |
|---|---|---|
| `match(caseLeft:caseRight:)` | requirement | the canonical eliminator — applies one of two functions depending on the case |
| `.a: A?` | extension | the left value, or `nil` if in the right case |
| `.b: B?` | extension | the right value, or `nil` if in the left case |
| `.isA: Bool` | extension | `true` when in the left case |
| `.isB: Bool` | extension | `true` when in the right case |
| `.bifoldMap(leftBy:rightBy:)` | extension | alias for `match`, with labels matching Haskell's `bimap`/`bifoldMap` naming convention |
| `.fromLeft(_:)` | extension | the left value, or a supplied default if in the right case |
| `.fromRight(_:)` | extension | the right value, or a supplied default if in the left case |
| `static func from(_:)` | extension | rebuilds `Self` from *any* other `SumType2` sharing the same `A`/`B` — the cross-type bridge |

```swift
let e: Either<String, Int> = .right(42)

e.match(caseLeft: { "error: \($0)" }, caseRight: { "value: \($0)" })   // "value: 42"
e.bifoldMap(leftBy: { "error: \($0)" }, rightBy: { "value: \($0)" })   // "value: 42" — same thing, Haskell-flavored name

e.a           // nil
e.b           // Optional(42)
e.isA         // false
e.isB         // true

e.fromLeft("default")    // "default" — .right, so the fallback is used
e.fromRight(0)            // 42        — .right, so the payload is used

// Cross-type bridge — resolves the source's case through match, then rebuilds via `Self`
let r = Result<Int, String>.from(Either<Int, String>.left(42))   // .success(42)
```

## Conforming types and their left/right mapping

Only three built-in types conform to `SumType2` today: `Either`, `Result`, and `Optional`. Read each conformance's `left`/`right` implementation directly rather than assuming a convention — the mapping is **not** uniform across types:

| Type | `.left` / `A` (case that satisfies `isA`) | `.right` / `B` (case that satisfies `isB`) |
|---|---|---|
| `Either<A, B>` | `.left(A)` | `.right(B)` |
| `Result<Success, Failure>` | `.success(Success)` | `.failure(Failure)` |
| `Optional<Wrapped>` | `.some(Wrapped)` | `.none` (as `Void`) |

Note the asymmetry: for `Either`, `.left` is conventionally the failure/error side and `.right` is the "happy path" (the Haskell mnemonic "right is right"). But `Result` and `Optional` map their *success* case (`.success`, `.some`) to `.left`/`A` — the opposite convention. Always check `.isA`/`.isB` against the concrete type's actual conformance (`Result+SumType.swift`, `Optional+SumType.swift`) rather than assuming `.right`/`B` means "success" universally.

```swift
Either<String, Int>.right(42).isB     // true  — .right is B for Either
Result<Int, Error>.success(42).isA    // true  — .success is A for Result, NOT B
Optional(42).isA                       // true  — .some is A for Optional
Optional<Int>.none.isB                 // true  — .none is B for Optional
```

`Validation<E, A>` is structurally a two-case type and ships its own `match(caseFailure:caseSuccess:)` with the same shape, but it does **not** conform to `SumType2` — it isn't a `Monad` either, and the library keeps its API surface separate rather than routing it through the shared protocol. To use a `Validation` value with a function generic over `SumType2`, bridge it first:

```swift
let v: Validation<String, Int> = .success(42)
summarize(v.toEither())   // Either<String, Int> conforms to SumType2 — bridge, then call
```

## Worked example: one function, three concrete types

```swift
func describe<S: SumType2>(_ s: S) -> String where S.A: CustomStringConvertible, S.B: CustomStringConvertible {
    s.match(
        caseLeft: { "A: \($0)" },
        caseRight: { "B: \($0)" }
    )
}

describe(Either<String, Int>.right(42))         // "B: 42"
describe(Result<Int, NSError>.success(42))       // "A: 42"   — success is A for Result
describe(42 as Int?)                             // "A: 42"   — Optional conforms implicitly via its extension
```

The same `describe` function, unmodified, handles all three — the caller doesn't need to know or care which concrete sum type it received.

## For Haskell developers

Haskell doesn't need a `SumType2` protocol because it doesn't need a shared *elimination interface* for two-case types in the first place. `Either a b` and `Maybe a` are ordinary algebraic data types, and pattern matching (`case`, `either`, `maybe`) works identically and universally on any ADT the compiler can see — there's no separate "protocol" step because structural pattern matching *is* the shared interface, built into the language for every sum type at once.

Swift's enums with associated values don't have that built-in universal elimination form. A `switch` over `Either` and a `switch` over `Result` are two unrelated pieces of code with no shared abstraction, even though the shapes are isomorphic — Swift's type system has no way to say "this enum has exactly two cases, shaped like a coproduct" without an explicit protocol declaring it so. `SumType2` is that explicit declaration: it exists specifically to recover, as a library-level protocol, the elimination-interface uniformity that Haskell gets from pattern matching being structural and available everywhere by default.

This also explains why the mapping isn't uniform (`Result.success` is `.left`/`A`, not `.right`/`B`): `SumType2` isn't reproducing Haskell's `Either`-with-a-canonical-`Right-is-success` convention — Haskell has no such single convention either, since `Maybe`, `Either`, and hypothetical two-case validation types each carry their own case order with no protocol unifying them. `SumType2` is Swift-specific plumbing to let generic code fold over these shapes; it isn't standing in for any single Haskell typeclass instance.
