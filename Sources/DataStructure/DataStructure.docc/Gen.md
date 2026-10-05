# ``Gen``

`Gen<R, Value>` is a composable, seedable random-value generator for property-based testing.

Property-based testing flips the usual test shape around: instead of hand-picking a handful of example inputs, you describe the *space* of valid inputs and let the framework generate many of them, checking that a property holds for all of them. The generator for that space needs two things a plain `Int.random(in:)` call doesn't give you: **composability** (build a generator for `User` out of generators for `String` and `Int`) and **reproducibility** (when a random case fails, you need to run that exact same case again to debug it, and "random" and "irreproducible" cannot go together in a test suite).

`Gen` is not a bespoke type, it is a `typealias` for an existing type in this library:

```swift-sketch
public typealias Gen<R: RandomNumberGenerator & Sendable, Value> = Stateful<R, Value>
```

`Gen<R, Value>` *is* `Stateful<R, Value>`, a computation that threads a random number generator through as its state and produces a `Value`. Because it's `Stateful`, `Gen` inherits **all** of `Stateful`'s `Functor`/`Applicative`/`Monad` machinery (`map`, `flatMap`, `zip`, `<£>`, `>>-`, every operator described in <doc:Stateful>) for free. There is no separate `Gen` monad instance to implement or test, composing generators is composing `Stateful` values. A generator is only a description, `(inout R) -> Value`, and there is deliberately no runner that creates the RNG for you.

---

## Seeding and reproducibility

Two supporting types make this concrete:

- **`AnyRandomNumberGenerator`**: a `Sendable` type-erased RNG, for when the RNG type must not appear in a signature (`Gen<AnyRandomNumberGenerator, V>`).
- **`SplitMix64`**: a small, fast, seedable PRNG (Steele, Lea & Flood, *"Fast Splittable Pseudorandom Number Generators,"* OOPSLA 2014). Given the same `UInt64` seed, it produces the same sequence every time, on every platform.

The examples use the source's own convention, a short alias that fixes the RNG:

```swift
import DataStructure

typealias G<V> = Gen<SplitMix64, V>

let die: G<Int> = .int(in: 1...6)

var rng = SplitMix64(seed: 42)
let value = die.run(&rng)                       // deterministic, same seed gives the same value
let many = die.array(ofCount: 100).run(&rng)    // [Int], 100 values from one reproducible sequence
```

For entropy, inject `SystemRandomNumberGenerator()` at the edge of the program, no runner creates an RNG for you:

```swift
var system = SystemRandomNumberGenerator()
let entropyDie: Gen<SystemRandomNumberGenerator, Int> = .int(in: 1...6)
let rolled = entropyDie.run(&system)
```

When a property-based test fails on some generated input, print the seed (not the generated value): replay by re-creating `SplitMix64(seed:)` with the printed seed and running the same generator.

---

## Worked example: composing a generator for a domain type

Because `Gen` is `Stateful`, building a generator for `User` is exactly building any other `Stateful` value out of smaller ones, via `zip` (applicative) or `flatMap` (monadic) when later generators depend on earlier results.

```swift
import DataStructure
import Foundation

struct User: Sendable {
    let id: UUID
    let name: String
    let age: Int
}

let userGen: G<User> = G.zip(
    .uuid(),
    .string(of: .letter(), count: .int(in: 3...8)),
    .int(in: 0...120)
).map(User.init)

var userRng = SplitMix64(seed: 1)
let oneUser = userGen.run(&userRng)                        // one deterministic User
let fiftyUsers = userGen.array(ofCount: 50).run(&userRng)  // 50 deterministic Users
```

`flatMap` is what you reach for when a later generator's *shape* depends on an earlier value, for instance, generating an array whose length is itself random:

```swift
// First draw a length in 1...3, then generate that many ints. The array's size
// depends on the earlier random choice, which is exactly what flatMap threads through.
let sizedArray: G<[Int]> = G.int(in: 1...3).flatMap { length in
    G.int(in: 0...9).array(ofCount: length)
}
```

---

## Reference

| Combinator | Signature (essence) | Example |
|---|---|---|
| `uint64` | `() -> Gen<R, UInt64>` | `Gen.uint64().run(&rng)` |
| `bool` | `() -> Gen<R, Bool>` | `Gen.bool().run(&rng)` |
| `int(in:)` | `(ClosedRange<Int>) -> Gen<R, Int>` | `Gen.int(in: 1...6).run(&rng)` |
| `double(in:)` | `(ClosedRange<Double>) -> Gen<R, Double>` | `Gen.double(in: 0...1).run(&rng)` |
| `uuid` | `() -> Gen<R, UUID>` | `Gen.uuid().run(&rng)` — well-formed version-4 UUID |
| `element(of:)` | `(C) -> Gen<R, C.Element?>` | `Gen.element(of: [10, 20, 30]).run(&rng)` — `nil` if empty |
| `character(in:)` | `(NonEmpty<Character>) -> Gen<R, Character>` | `Gen.character(in: NonEmpty(head: "x", tail: ["y"])).run(&rng)` |
| `letter` | `() -> Gen<R, Character>` | `Gen.letter().run(&rng)` — `A–Z`, `a–z` |
| `digit` | `() -> Gen<R, Character>` | `Gen.digit().run(&rng)` — `0–9` |
| `alphanumeric` | `() -> Gen<R, Character>` | `Gen.alphanumeric().run(&rng)` |
| `string(of:count:)` | `(Gen<R, Character>, Gen<R, Int>) -> Gen<R, String>` | `Gen.string(of: .letter(), count: .int(in: 5...5)).run(&rng)` |
| `array(ofCount:)` | `(Int) -> Gen<R, [A]>` or `(Gen<R, Int>) -> Gen<R, [A]>` | `Gen.int(in: 0...9).array(ofCount: 7).run(&rng)` |
| `optional` | `() -> Gen<R, A?>` | `Gen.int(in: 0...9).optional().run(&rng)` — `nil` or a value, 50/50 |
| `one(of:)` | `(NonEmpty<Gen<R, A>>) -> Gen<R, A>` | `Gen.one(of: NonEmpty(head: .int(in: 0...0), tail: [.int(in: 100...100)]))` |
| `frequency(_:)` | `(NonEmpty<(Int, Gen<R, A>)>) -> Gen<R, A>` | `Gen.frequency(NonEmpty(head: (10, .int(in: 0...0)), tail: [(1, .int(in: 1...1))]))` — weighted choice |

All higher-order combinators (`array`, `optional`) are instance methods on any `Gen<R, A>`, so they compose with primitives without any extra glue: `Gen.int(in: 0...9).array(ofCount: 7)` reads left-to-right as "an int, seven times."

---

## For Haskell developers

`Gen` is a direct structural match for QuickCheck's `Test.QuickCheck.Gen`. The naming is deliberately close:

| This library | QuickCheck (`Test.QuickCheck.Gen`) | Notes |
|---|---|---|
| `Gen.element(of:)` | `elements` | uniform choice from a collection |
| `Gen.one(of:)` | `oneof` | uniform choice between generators |
| `Gen.frequency(_:)` | `frequency` | weighted choice between generators |
| `Gen<R, A>` composed via `map`/`flatMap`/`zip` | `arbitrary` + the `Gen` `Monad`/`Applicative` instance | QuickCheck's `Arbitrary` typeclass picks a default generator per type; this library has you construct the generator explicitly and compose it, since Swift has no typeclass-style dispatch |
| `gen.run(&rng)` | `unGen gen (mkQCGen seed) size` | QuickCheck's `generate` (IO, unseeded) has no counterpart here by design, the RNG is always injected. QuickCheck's shrinking (`shrink`) has no equivalent either, this library generates and replays via seed, but does not automatically minimize failing cases |

For the foundational argument behind generator-driven testing itself, see Claessen & Hughes, *["QuickCheck: A Lightweight Tool for Random Testing of Haskell Programs"](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)* (ICFP 2000) — the paper that introduced `Gen`, `elements`, `oneof`, and `frequency` under those exact names.

---

## Module

```swift-sketch
import DataStructure   // Gen<R, Value> (typealias of Stateful), AnyRandomNumberGenerator, SplitMix64
```
