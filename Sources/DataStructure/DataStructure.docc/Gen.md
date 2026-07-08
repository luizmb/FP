# ``Gen``

`Gen<Value>` — a composable, seedable random-value generator for property-based testing.

Property-based testing flips the usual test shape around: instead of hand-picking a handful of example inputs, you describe the *space* of valid inputs and let the framework generate many of them, checking that a property holds for all of them. The generator for that space needs two things a plain `Int.random(in:)` call doesn't give you: **composability** (build a generator for `User` out of generators for `String` and `Int`) and **reproducibility** (when a random case fails, you need to run that exact same case again to debug it — "random" and "irreproducible" cannot go together in a test suite).

`Gen` is not a bespoke type built to solve this — it is a `typealias` for an existing type in this library:

```swift
public typealias Gen<Value> = Stateful<AnyRandomNumberGenerator, Value>
```

`Gen<Value>` *is* `Stateful<AnyRandomNumberGenerator, Value>` — a computation that threads a random number generator through as its state and produces a `Value`. Because it's `Stateful`, `Gen` inherits **all** of `Stateful`'s `Functor`/`Applicative`/`Monad` machinery — `map`, `flatMap`, `zip`, `<£>`, `>>-`, every operator and transformer described in <doc:Stateful> — for free. There is no separate `Gen` monad instance to implement or test; composing generators is composing `Stateful` values.

---

## Seeding and reproducibility

Two supporting types make this concrete:

- **`AnyRandomNumberGenerator`** — a `Sendable`, type-erased `RandomNumberGenerator`. Erasing to one concrete type is what lets `Gen` be a plain, freely-composable generic alias rather than a type generic over its RNG.
- **`SplitMix64`** — a small, fast, seedable PRNG (Steele, Lea & Flood, *"Fast Splittable Pseudorandom Number Generators,"* OOPSLA 2014). Given the same `UInt64` seed, it produces the same sequence every time, on every platform.

```swift
import DataStructure

let die: Gen<Int> = .int(in: 1...6)

die.generate(seed: 42)              // deterministic — same seed, same value, every run
die.samples(seed: 42, count: 100)   // [Int] — 100 values from one reproducible sequence

die.generate()                       // uses SystemRandomNumberGenerator — not reproducible
```

When a property-based test fails on some generated input, printing the seed (not the generated value) is what lets you replay the exact same failing case later with `samples(seed:count:)` or `generate(seed:)`.

---

## Worked example: composing a generator for a domain type

Because `Gen` is `Stateful`, building a generator for `User` is exactly building any other `Stateful` value out of smaller ones — via `zip` (applicative) or `flatMap` (monadic) when later generators depend on earlier results.

```swift
import DataStructure
import Foundation

struct User: Sendable {
    let id: UUID
    let name: String
    let age: Int
}

let userGen: Gen<User> = Gen.zip3(
    .uuid(),
    .string(of: .letter(), count: .int(in: 3...8)),
    .int(in: 0...120)
).map(User.init)

userGen.generate(seed: 1)                 // one deterministic User
userGen.samples(seed: 1, count: 50)        // 50 deterministic Users
```

`flatMap` is what you reach for when a later generator's *shape* depends on an earlier value — for instance, generating an array whose length is itself random:

```swift
// First draw a length in 1...3, then generate that many ints — the array's size
// depends on the earlier random choice, which is exactly what flatMap threads through.
let sizedArray: Gen<[Int]> = Gen.int(in: 1...3).flatMap { length in
    Gen.int(in: 0...9).array(ofCount: length)
}
```

---

## Reference

| Combinator | Signature (essence) | Example |
|---|---|---|
| `uint64` | `() -> Gen<UInt64>` | `Gen.uint64().generate(seed: 1)` |
| `bool` | `() -> Gen<Bool>` | `Gen.bool().generate(seed: 1)` |
| `int(in:)` | `(ClosedRange<Int>) -> Gen<Int>` | `Gen.int(in: 1...6).generate(seed: 1)` |
| `double(in:)` | `(ClosedRange<Double>) -> Gen<Double>` | `Gen.double(in: 0...1).generate(seed: 1)` |
| `uuid` | `() -> Gen<UUID>` | `Gen.uuid().generate(seed: 1)` — well-formed version-4 UUID |
| `element(of:)` | `(C) -> Gen<C.Element?>` | `Gen.element(of: [10, 20, 30]).generate(seed: 1)` — `nil` if empty |
| `character(in:)` | `(NonEmpty<Character>) -> Gen<Character>` | `Gen.character(in: NonEmpty(head: "x", tail: ["y"])).generate(seed: 1)` |
| `letter` | `() -> Gen<Character>` | `Gen.letter().generate(seed: 1)` — `A–Z`, `a–z` |
| `digit` | `() -> Gen<Character>` | `Gen.digit().generate(seed: 1)` — `0–9` |
| `alphanumeric` | `() -> Gen<Character>` | `Gen.alphanumeric().generate(seed: 1)` |
| `string(of:count:)` | `(Gen<Character>, Gen<Int>) -> Gen<String>` | `Gen.string(of: .letter(), count: .int(in: 5...5)).generate(seed: 1)` |
| `array(ofCount:)` | `(Int) -> Gen<[A]>` or `(Gen<Int>) -> Gen<[A]>` | `Gen.int(in: 0...9).array(ofCount: 7).generate(seed: 1)` |
| `optional` | `() -> Gen<A?>` | `Gen.int(in: 0...9).optional().generate(seed: 1)` — `nil` or a value, 50/50 |
| `one(of:)` | `(NonEmpty<Gen<A>>) -> Gen<A>` | `Gen.one(of: NonEmpty(head: .int(in: 0...0), tail: [.int(in: 100...100)]))` |
| `frequency(_:)` | `(NonEmpty<(Int, Gen<A>)>) -> Gen<A>` | `Gen.frequency(NonEmpty(head: (10, .int(in: 0...0)), tail: [(1, .int(in: 1...1))]))` — weighted choice |
| `generate(seed:)` | `(UInt64) -> A` | `die.generate(seed: 42)` — one reproducible value |
| `generate()` | `() -> A` | `die.generate()` — one value, system randomness |
| `samples(seed:count:)` | `(UInt64, Int) -> [A]` | `die.samples(seed: 42, count: 100)` — reproducible sequence |

All higher-order combinators (`array`, `optional`) are instance methods on any `Gen<A>`, so they compose with primitives without any extra glue — `Gen.int(in: 0...9).array(ofCount: 7)` reads left-to-right as "an int, seven times."

---

## For Haskell developers

`Gen` is a direct structural match for QuickCheck's `Test.QuickCheck.Gen`. The naming is deliberately close:

| This library | QuickCheck (`Test.QuickCheck.Gen`) | Notes |
|---|---|---|
| `Gen.element(of:)` | `elements` | uniform choice from a collection |
| `Gen.one(of:)` | `oneof` | uniform choice between generators |
| `Gen.frequency(_:)` | `frequency` | weighted choice between generators |
| `Gen<A>` composed via `map`/`flatMap`/`zip` | `arbitrary` + the `Gen` `Monad`/`Applicative` instance | QuickCheck's `Arbitrary` typeclass picks a default generator per type; this library has you construct the generator explicitly and compose it, since Swift has no typeclass-style dispatch |
| `generate(seed:)` / `samples(seed:count:)` | `generate` run through a seeded `QCGen` | QuickCheck's shrinking (`shrink`) has no equivalent here — this library generates and replays via seed, but does not automatically minimize failing cases |

For the foundational argument behind generator-driven testing itself, see Claessen & Hughes, *["QuickCheck: A Lightweight Tool for Random Testing of Haskell Programs"](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)* (ICFP 2000) — the paper that introduced `Gen`, `elements`, `oneof`, and `frequency` under those exact names.

---

## Module

```swift
import DataStructure   // Gen (typealias of Stateful), AnyRandomNumberGenerator, SplitMix64
```
