# FP

FP is a Swift library that brings functional programming patterns to your codebase in a composable, type-safe way. It extends Swift's built-in types (`Optional`, `Result`, `Array`, `Publisher`, async/await `Task`, `AsyncSequence`) and introduces new data structures that make common patterns — error handling, dependency injection, state threading, validation — explicit, predictable, and easy to test.

The library draws from Haskell and Scala Cats conventions and is designed to be used incrementally: start with just the core extensions and adopt more as your comfort grows.

## Contents

- [Learning Resources](#learning-resources)
- [Installation](#installation)
  - [Modules](#modules)
    - [`CoreFP` — the foundation](#corefp--the-foundation)
    - [`CoreFPOperators` — expressive operator sugar](#corefpoperators--expressive-operator-sugar-optional)
    - [`DataStructure` — additional functional data structures](#datastructure--additional-functional-data-structures-optional)
    - [`DataStructureOperators` — operators for data structures](#datastructureoperators--operators-for-data-structures-optional)
  - [Choosing what to import](#choosing-what-to-import)
- [Library Overview](#library-overview)
  - [Joining things together (Semigroup)](#joining-things-together-semigroup)
    - [Semigroup operator](#semigroup-operator-optional-requires-corefpoperators)
  - [Neutral element when joining (Monoid)](#neutral-element-when-joining-monoid)
  - [Map (Functor)](#map-functor)
    - [Bifunctor](#bifunctor)
    - [Covariance, contravariance, and contramap](#covariance-contravariance-and-contramap)
    - [Profunctor and dimap](#profunctor-and-dimap)
    - [Functor operators](#functor-operators-optional-requires-corefpoperators)
  - [Zip / Apply (Applicative)](#zip--apply-applicative)
    - [Applicative operators](#applicative-operators-optional-requires-corefpoperators)
  - [FlatMap (Monad)](#flatmap-monad)
    - [Monad operators](#monad-operators-optional-requires-corefpoperators)
  - [Fold (Foldable)](#fold-foldable)
  - [Traverse (Traversable)](#traverse-traversable)
  - [Alternative (Choice)](#alternative-choice)
  - [Comonad (Extend)](#comonad-extend)
    - [Comonad operators](#comonad-operators-optional-requires-datastructureoperators)
  - [Functional Getter / Setter for Structs (Lens)](#functional-getter--setter-for-structs-lens)
    - [Lens operators](#lens-operators-optional-requires-corefpoperators)
  - [Functional Getter / Setter for Enums (Prism)](#functional-getter--setter-for-enums-prism)
    - [Prism operators](#prism-operators-optional-requires-corefpoperators)
  - [Assembling Optics (AffineTraversal)](#assembling-optics-affinetraversal)
  - [Bidirectional Conversions (Iso)](#bidirectional-conversions-iso)
    - [Iso operators](#iso-operators-optional-requires-corefpoperators)
  - [Composing Transformations (Endo)](#composing-transformations-endo)
  - [SumType2 — Shared Interface for Two-Case Types](#sumtype2--shared-interface-for-two-case-types)
  - [Utilities](#utilities)
  - [Operator Reference](#operator-reference)
  - [Types](#types)
    - [CoreFP](#corefp)
    - [DataStructure](#datastructure)
- [Contributing](#contributing)
- [Testing](#testing)
- [Platform Support](#platform-support)
- [License](#license)

## Learning Resources

New to functional programming? These are some of the best starting points:

- [Functors, Applicatives, and Monads in Pictures](https://mokacoding.com/blog/functor-applicative-monads-in-pictures/) — a visual, intuition-first introduction to the core concepts
- [Learn You a Haskell for Great Good!](https://learnyouahaskell.github.io/) — a beginner-friendly free book that explains the ideas behind this library


## Installation

FP is a Swift Package Manager library and is designed to be **modular**: import only what you need. Each module builds on the previous one, so you can start small and expand.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/luizmb/FP.git", from: "1.0.0")
]
```

### Modules

#### `CoreFP` — the foundation

The minimum you need. Adds several functional operations to Swift's built-in types — `Optional`, `Result`, `Array`, Combine's `Publisher`, and Swift Concurrency's `AsyncSequence` and more.

#### `CoreFPOperators` — expressive operator sugar _(optional)_

Adds custom symbolic operators for all `CoreFP` types. Using operators is entirely optional — every operator has a named function equivalent in `CoreFP` — but they allow a more concise, expression-oriented style.

> **Before adding this module**, check your codebase for existing definitions of these symbols. Some (like `<>`, `>>>`, `|>`, or `^`) are used in other libraries and could cause conflicts or ambiguity errors at the call site.

#### `DataStructure` — additional functional data structures _(optional)_

Adds new types that are common in functional languages but absent from Swift's standard library, such as `Either<A, B>`, `Validation<E, A>`, `Reader<Environment, Output>`, `Stateful<S, A>`, `Writer<Log, A>`.

#### `DataStructureOperators` — operators for data structures _(optional)_

Provides the same operator sugar as `CoreFPOperators`, but for the types in `DataStructure`. This module depends on both `DataStructure` and `CoreFPOperators`, and is only useful when both are present.

---

### Choosing what to import

| You want | Import |
|----------|--------|
| Functional operations on built-in types only | `CoreFP` |
| The above plus symbolic operators | `CoreFP` + `CoreFPOperators` |
| Built-in types + additional data structures | `CoreFP` + `DataStructure` |
| Everything, with operator syntax | `FP` |

The `FP` umbrella product re-exports all four modules, so a single line covers everything:

```swift
import FP
```

Or import selectively:

```swift
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
```

Add the chosen products to your target in `Package.swift`:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "FP", package: "FP")  // or any individual module
    ]
)
```

---

## Library Overview

### Joining things together (Semigroup)

A **Semigroup** is any type where two values can be combined into one value of the same type. You already know several semigroups from everyday Swift:

```swift
String.combine("Hello, ", "World!")  // "Hello, World!"
Array.combine([1, 2], [3, 4])        // [1, 2, 3, 4]
```

The only rule is that combining must be *associative* — it shouldn't matter how you group the operations, only the order:

```swift
// These two must always be equivalent:
String.combine(String.combine("a", "b"), "c")  // "abc"
String.combine("a", String.combine("b", "c"))  // "abc"
```

This library defines a `Semigroup` protocol, implemented by `String`, `Array`, `Optional`, `Dictionary`, `Set`, `Result`, and numeric types like `Int`, `Double`, and `CGFloat`, as well as `Bool` — but more on those in a moment. You can also make your own types conform to it by implementing `combine`.

Curiosity: lasagna is a semigroup, because putting one lasagna on top of another gives you lasagna.

![Lasagna + Lasagna = Lasagna](docs/lasagna.jpg)

`sconcat` reduces a non-empty sequence using `combine`:

```swift
sconcat("Hello", [", ", "World", "!"])  // "Hello, World!"
sconcat([1, 2], [[3, 4], [5, 6]])       // [1, 2, 3, 4, 5, 6]
```

#### Semigroup operator _(optional, requires CoreFPOperators)_

`<>` is the infix operator for `combine`:

```swift
"Hello, " <> "World!"     // "Hello, World!"
[1, 2] <> [3, 4]          // [1, 2, 3, 4]
```

---

### Neutral element when joining (Monoid)

A **Monoid** is a semigroup with one extra requirement: there must be a neutral element (called `identity`) that leaves any value unchanged when combined with it — regardless of which side it appears on.

```swift
"" <> "hello"  // "hello" — empty string is the identity for String
"hello" <> ""  // "hello"

[] <> [1, 2]   // [1, 2] — empty array is the identity for Array
[1, 2] <> []   // [1, 2]
```

You can access the identity through the static property:

```swift
String.identity   // ""
[Int].identity    // []
```

`mconcat` collapses an entire array using `combine`, starting from `identity`:

```swift
mconcat(["Hello", ", ", "World", "!"])  // "Hello, World!"
mconcat([[1, 2], [3], [4, 5]])          // [1, 2, 3, 4, 5]
mconcat([String]())                     // "" — empty input returns identity
```

**Numbers and Booleans**

Most numeric types can be combined in more than one way — you can add them or multiply them — so there isn't a single obvious `Monoid` instance for `Int`. Swift also doesn't allow the same type to conform to a protocol twice.

This library solves that with lightweight wrapper types:

```swift
// Addition — identity is 0
Int.Monoids.Sum.combine(3, 4)                              // Sum(7)
Int.Monoids.Sum.identity                                   // Sum(0)
mconcat([1, 2, 3] as [Int.Monoids.Sum]).rawValue           // 6

// Multiplication — identity is 1
Int.Monoids.Product.combine(3, 4)                          // Product(12)
Int.Monoids.Product.identity                               // Product(1)
mconcat([2, 3, 4] as [Int.Monoids.Product]).rawValue       // 24

// Minimum — identity is Int.max (any value beats it)
Int.Monoids.Min.combine(7, 3)                              // Min(3)
Int.Monoids.Min.identity.rawValue                          // Int.max
mconcat([5, 1, 9] as [Int.Monoids.Min]).rawValue           // 1

// Maximum — identity is Int.min (any value beats it)
Int.Monoids.Max.combine(7, 3)                              // Max(7)
Int.Monoids.Max.identity.rawValue                          // Int.min
mconcat([5, 1, 9] as [Int.Monoids.Max]).rawValue           // 9
```

The same pattern applies to `UInt`, `Float`, `Double`, `CGFloat`, and all other numeric types. Float literals work too:

```swift
Double.Monoids.Sum.combine(1.5, 2.5)                       // Sum(4.0)
mconcat([1.0, 2.5, 0.5] as [Double.Monoids.Sum]).rawValue  // 4.0
Double.Monoids.Min.combine(2.5, 1.1)                       // Min(1.1)
Double.Monoids.Max.combine(2.5, 1.1)                       // Max(2.5)
```

**SIMD vectors** get the same four wrappers via `SIMDMonoid`, operating element-wise on each lane. Integer scalars use wrapping arithmetic (`&+`, `&*`) while floating-point scalars use standard arithmetic:

```swift
// Element-wise sum — identity is the zero vector
let a = SIMD4<Int>.Monoids.Sum(SIMD4(1, 2, 3, 4))
let b = SIMD4<Int>.Monoids.Sum(SIMD4(10, 20, 30, 40))
SIMD4<Int>.Monoids.Sum.combine(a, b).rawValue               // SIMD4(11, 22, 33, 44)

// Element-wise product — identity is the ones vector
SIMD2<Float>.Monoids.Product.combine(
    .init(SIMD2(2.0, 3.0)),
    .init(SIMD2(4.0, 5.0))
).rawValue                                                   // SIMD2(8.0, 15.0)

// Element-wise min / max
let v = [SIMD2(5, 9), SIMD2(1, 3), SIMD2(8, 2)].map { SIMD2<Int>.Monoids.Min($0) }
mconcat(v).rawValue                                          // SIMD2(1, 2)
```

All SIMD sizes from `SIMD2` through `SIMD64` are supported for every `SIMDMonoidScalar` type (`Int`, `Int8`–`Int64`, `UInt`–`UInt64`, `Float`, `Double`).

`Bool` works the same way:

```swift
// Conjunction (&&) — identity is true
Bool.Monoids.And.combine(.init(true), .init(false))   // And(false)
Bool.Monoids.And.identity                             // And(true)
mconcat([Bool.Monoids.And(true), .init(true), .init(false)]).rawValue  // false

// Disjunction (||) — identity is false
Bool.Monoids.Or.combine(.init(false), .init(true))    // Or(true)
Bool.Monoids.Or.identity                              // Or(false)
mconcat([Bool.Monoids.Or(false), .init(false), .init(true)]).rawValue  // true

// Exclusive disjunction (!=) — identity is false
Bool.Monoids.Xor.combine(.init(true), .init(false))   // Xor(true)
Bool.Monoids.Xor.combine(.init(true), .init(true))    // Xor(false)
Bool.Monoids.Xor.identity                             // Xor(false)
mconcat([Bool.Monoids.Xor(true), .init(false), .init(true)]).rawValue  // false
```

An empty tray of lasagna would be the identity element — making lasagna a monoid too.

### Map (Functor)

A **Functor** is any container-like structure whose contents you can transform without unwrapping it. The transformation is applied to the value inside, and the container comes back with the new value in it — shape preserved, contents changed.

Swift already ships with this for the most common types:

```swift
[1, 2, 3].map { $0 * 2 }                         // [2, 4, 6]
Optional(5).map { $0 * 2 }                       // Optional(10)
Result<Int, any Error>.success(5).map { $0 * 2 } // .success(10)
```

This library also provides `fmap` as a free function, which is useful for point-free composition:

```swift
fmap({ $0 * 2 }, Optional(5))  // Optional(10)
```

#### Bifunctor

Some containers have two type parameters, not one. `Result<Success, Failure>` is the obvious example: `.map` transforms the success side, and `.mapError` transforms the failure side.

In FP languages, we normally have a function `.bimap` to allow both sides to be transformed in one go. This library introduces this option as well.

```swift
let result: Result<Int, String> = .failure("not found")

result.bimap(
    { $0 * 2 },          // success path (not reached here)
    { "Error: \($0)" }   // failure path
)
// .failure("Error: not found")

Result<Int, String>.success(21).bimap(
    { $0 * 2 },
    { "Error: \($0)" }
)
// .success(42)
```

#### Covariance, contravariance, and contramap

When you `map` over a container, the output type changes "in the same direction" as the function you provide — give it `(Int) -> String` and you get `Container<String>` back. This is **covariance**: the type parameter varies with the transform.

But some type parameters vary in the *opposite* direction, and those are called **contravariant**. The clearest example is a function's input. If you have a function `(String) -> Bool` (say, a validator), you can adapt it to also accept `Int` by first converting `Int → String`. You're not mapping the output — you're pre-processing the input. That "pre-processing the input" operation is called `contramap`.

This library makes the concept concrete via the `Reader` type (a wrapper around `(Environment) -> Output`). In a dependency injection context, `contramapEnvironment` lets a component that needs a specific sub-dependency be adapted to accept the whole root environment:

```swift
struct Dependencies {
    var urlRequester: URLRequester
    var jsonParser: JSONParser
    var dateNow: DateNow
    var dispatchQueueMain: DispatchQueueMain
}

// A reader scoped to just the URLRequester sub-dependency
let fetchItems: Reader<URLRequester, [Item]> = Reader { $0.get("/items") }

// contramapEnvironment zooms out: adapt it to accept the full Dependencies root
let fetchItemsFromRoot: Reader<Dependencies, [Item]> = fetchItems.contramapEnvironment(\.urlRequester)
```

#### Profunctor and dimap

A **Profunctor** is a type that is covariant in one parameter and contravariant in another. Plain functions are the textbook example: `(A) -> B` can be mapped on the output (covariant in `B`) and contramapped on the input (contravariant in `A`). That makes functions profunctors.

`dimap` does both in one call — narrowing the environment and transforming the output in a single expression:

```swift
// A reader scoped to just the URLRequester
let checkReachability: Reader<URLRequester, Bool> = Reader { $0.isReachable }

// Narrow the input from Dependencies to URLRequester, and describe the Bool result as a String
let serviceStatus: Reader<Dependencies, String> = checkReachability.dimap(
    \.urlRequester,                               // Dependencies → URLRequester (narrow the environment)
    { $0 ? "service online" : "service offline" } // Bool → String (describe the result)
)
```

#### Functor operators _(optional, requires CoreFPOperators)_

Symbolic operators are syntactic sugar — every one of them delegates to a named function in `CoreFP`. Use them when they make the code more readable, ignore them when they don't.

`<£>` maps a function over a container (function on the left):

```swift
{ $0 * 2 } <£> Optional(5)                         // Optional(10)
{ $0 * 2 } <£> [1, 2, 3]                           // [2, 4, 6]
{ $0 * 2 } <£> Result<Int, String>.success(5)       // .success(10)
{ $0 * 3 } <£> Just(2).eraseToAnyPublisher()        // publisher of 6
```

`<&>` is the flipped version — container on the left:

```swift
Optional(5) <&> { $0 * 2 }                         // Optional(10)
[1, 2, 3] <&> { $0 * 2 }                           // [2, 4, 6]
Result<Int, String>.success(5) <&> { $0 * 2 }      // .success(10)
Just(2).eraseToAnyPublisher() <&> { $0 * 3 }       // publisher of 6
```

`£>` replaces the contents with a constant (container on the left, value on the right):

```swift
Optional(5) £> "hello"                              // Optional("hello")
[1, 2, 3] £> "x"                                   // ["x", "x", "x"]
Result<Int, String>.success(42) £> "done"           // .success("done")
Just(2).eraseToAnyPublisher() £> "done"             // publisher of "done"
```

`<£` is the flipped version — value on the left:

```swift
"hello" <£ Optional(5)                              // Optional("hello")
"x" <£ [1, 2, 3]                                   // ["x", "x", "x"]
"done" <£ Result<Int, String>.success(42)           // .success("done")
"done" <£ Just(2).eraseToAnyPublisher()             // publisher of "done"
```

---

### Zip / Apply (Applicative)

**Zip** combines two containers into one container of pairs. The key insight is that the containers remain independent until you combine them:

```swift
zip([1, 2, 3], ["a", "b", "c"])       // [(1, "a"), (2, "b"), (3, "c")]
zip(Optional(1), Optional(2))          // Optional((1, 2))
zip(Optional(1), Optional<Int>.none)   // nil — one nil means the pair is nil
```

For `Array`, `zip` pairs elements by index (the shorter array wins). For `Optional`, both values must be present for anything to come out. For `Publisher`, it waits until both have emitted and pairs them as they arrive.

`Result` doesn't have a stdlib `zip`, but this library adds it:

```swift
zip(Result<Int, String>.success(1), Result<Int, String>.success(2))   // .success((1, 2))
zip(Result<Int, String>.success(1), Result<Int, String>.failure("!")) // .failure("!")
```

**Apply**

Apply is a related operation: what if the *function itself* is inside a container? `apply` unwraps both the function and the value, applies the function, and wraps the result back up:

```swift
Optional({ $0 * 2 }).apply(Optional(3))   // Optional(6)
Optional<(Int) -> Int>.none.apply(Optional(3))  // nil
```

For `Array`, apply gives every combination — each function applied to every value:

```swift
[{ $0 + 1 }, { $0 * 10 }].apply([1, 2])  // [2, 3, 10, 20]
```

The relationship between `zip` and `apply`: `apply` is essentially `zip` followed by `map`. First zip the function-container with the value-container to get pairs, then map `{ (fn, value) in fn(value) }` over the pairs. This library implements both, and internally they delegate to the same logic.

Types that support `apply` are called **Applicatives**. Every Monad is an Applicative, but not vice versa — Applicatives can't express sequential dependencies between steps (you'll need `flatMap` for that).

**Parallel execution**

Because `zip` and `apply` combine *independent* effects, they can run concurrently. When you zip two `DeferredTask` values, both start immediately and the result becomes available when the slower one finishes. `flatMap`, by contrast, can only start the second task after the first provides a value — it is inherently sequential.

Use `zip` when two effects don't depend on each other. Use `flatMap` when they do.

#### Applicative operators _(optional, requires CoreFPOperators)_

`<*>` applies a wrapped function to a wrapped value (function container on the left):

```swift
Optional({ $0 + 41 }) <*> Optional(1)               // Optional(42)
[{ $0 * 2 }, { $0 * 3 }] <*> [1, 2]                 // [2, 4, 3, 6]
Result.success({ $0 * 2 }) <*> Result.success(21)    // .success(42)
Just({ $0 + 1 }).eraseToAnyPublisher() <*> Just(41).eraseToAnyPublisher()
```

`*>` sequences two effects and keeps the *right* result — the left effect still runs, but its value is discarded:

```swift
Optional(42) *> Optional("hello")   // Optional("hello") — 42 ran, but only "hello" survives
[1, 2] *> ["a", "b"]               // ["a", "b", "a", "b"]
Result<Int, String>.success(42) *> Result.success("hello")  // .success("hello")
```

`<*` keeps the *left* result instead:

```swift
Optional("hello") <* Optional(42)               // Optional("hello")
["a", "b"] <* [1, 2]                            // ["a", "a", "b", "b"]
Result.success("hello") <* Result.success(42)   // .success("hello")
```

---

### FlatMap (Monad)

`map` transforms the value *inside* a container. But sometimes the transform itself produces a container, and you'd end up with a nested one:

```swift
Optional("42").map { Int($0) }   // Optional<Optional<Int>> — nested, awkward
```

`flatMap` does the same thing, then flattens the result:

```swift
Optional("42").flatMap { Int($0) }   // Optional<Int> — flat
Optional("xx").flatMap { Int($0) }   // nil
```

This "apply a container-returning function, then flatten" is exactly what a **Monad** is. The name sounds academic but the idea is familiar: optional chaining (`foo?.bar?.baz`) is monadic thinking in disguise. Each `?.` is a `flatMap` step that stops the chain if anything is `nil`.

The shape of `flatMap` is always the same:

```swift
func flatMap<B>(_ transform: (A) -> Container<B>) -> Container<B>
```

But what it *does* depends entirely on the container — the same structure solves a different problem for each type.

**Optional** — failure propagation

Each step can fail, and the chain stops at the first `nil`:

```swift
func findUser(id: Int) -> User? { ... }
func findAddress(user: User) -> Address? { ... }
func city(from address: Address) -> String? { ... }

let result = findUser(id: 42)
    .flatMap(findAddress)
    .flatMap(city)
// String? — nil if any step failed
```

**Array** — nondeterminism

Each step can return *multiple* results. `flatMap` collects all combinations:

```swift
[1, 2, 3].flatMap { [$0, $0 * 10] }   // [1, 10, 2, 20, 3, 30]
```

Think of it as "for each input element, generate zero or more output elements, then collect everything flat."

**Publisher / DeferredTask** — async sequencing

The second effect can't start until the first finishes and provides its value:

```swift
fetchUser(id: 42)
    .flatMap { user in fetchPermissions(for: user) }
    .flatMap { perms in loadDashboard(permissions: perms) }
```

Unlike `zip` (which runs effects in parallel), `flatMap` is always serial. Step two *depends on* the result of step one — that's exactly when you reach for `flatMap`.

#### Monad operators _(optional, requires CoreFPOperators)_

`>>-` is bind with the container on the left — same argument order as `flatMap`:

```swift
Optional("42") >>- { Int($0) }                          // Optional(42)
[1, 2] >>- { [$0, $0 * 10] }                            // [1, 10, 2, 20]
Result.success("2") >>- { Result.success(Int($0) ?? 0) } // .success(2)
Just(42).eraseToAnyPublisher() >>- { Just($0 * 2).eraseToAnyPublisher() }
```

`-<<` is the flipped version — function on the left, container on the right:

```swift
{ Int($0) } -<< Optional("42")   // Optional(42)
```

`>=>` composes two "Kleisli arrows" — functions that return containers — into one:

```swift
let parseInt: (String) -> Int? = { Int($0) }
let doubleIt: (Int) -> Int? = { .some($0 * 2) }

let parseAndDouble = parseInt >=> doubleIt
parseAndDouble("21")   // Optional(42)
parseAndDouble("xx")   // nil
```

This is function composition for container-returning functions. `<<<` and `>>>` compose regular functions; `>=>` and `<=<` compose Kleisli arrows.

`<=<` is the right-to-left version:

```swift
let parseAndDouble = doubleIt <=< parseInt
```

---

### Fold (Foldable)

A **Foldable** is any structure you can collapse into a single value by visiting each element. Arrays are the obvious example, but `Optional` is foldable too — it has either zero or one element.

```swift
// withDefault — provide a fallback when a value is absent (curried, for composition)
withDefault(0)(Optional(42))   // 42
withDefault(0)(nil)            // 0

// fold — collapse an Optional to a single type
Optional(5).fold(onNone: 0, onSome: { $0 * 2 })   // 10
(nil as Int?).fold(onNone: 0, onSome: { $0 * 2 }) // 0

// Static variant for point-free composition
let safeParse: (String) -> Int = { Int($0) }.map >>> Optional.fold(onNone: -1, onSome: id)

// foldMap — map each element to a Monoid, then combine them
Optional(3).foldMap { Int.Monoids.Sum($0) }        // Sum(3)
(nil as Int?).foldMap { Int.Monoids.Sum($0) }      // Sum(0)  — identity

[1, 2, 3].foldMap { Int.Monoids.Sum($0) }          // Sum(6)

// foldLeft / foldRight on Array (curried)
Array.foldLeft(0, +)([1, 2, 3, 4])    // 10  — (((0+1)+2)+3)+4
Array.foldRight(-, 0)([1, 2, 3])      // 2   — 1-(2-(3-0))

// toList — Optional as a zero-or-one list
Optional(42).toList   // [42]
(nil as Int?).toList  // []
```

---

### Traverse (Traversable)

A **Traversable** is a structure you can map over with a function that produces a container, collecting all the containers into one. Think of it as "map, then flip the nesting."

The two key operations are:
- `traverse` — map and flip at once
- `sequence` — flip without mapping (the common case)

```swift
// Array<Optional> → Optional<Array>
// All must be present; one nil collapses the whole result
[Optional(1), Optional(2), Optional(3)].sequence()   // Optional([1, 2, 3])
[Optional(1), nil, Optional(3)].sequence()           // nil

["1", "2", "3"].traverse { Int($0) }    // Optional([1, 2, 3])
["1", "x", "3"].traverse { Int($0) }   // nil

// Array<Result> → Result<Array>
[Result<Int, MyError>.success(1), .success(2)].sequence()           // .success([1, 2])
[Result<Int, MyError>.success(1), .failure(.err)].sequence()        // .failure(.err)

// Optional<Array> → Array<Optional>
Optional([1, 2, 3]).sequence()   // [Optional(1), Optional(2), Optional(3)]
(nil as [Int]?).sequence()       // [nil]

// Optional<Result> → Result<Optional>
Optional(Result<Int, MyError>.success(42)).sequence()   // .success(Optional(42))
(nil as Result<Int, MyError>?).sequence()               // .success(nil)
```

---

### Alternative (Choice)

**Alternative** models a choice between two effects: try the first; if it's "empty" (nil, [], failure), fall back to the second.

```swift
// Optional — first non-nil wins
(nil as Int?) <|> Optional(3)   // Optional(3)
Optional(1)   <|> Optional(3)   // Optional(1) — first wins if present

// Array — concatenation
[1, 2] <|> [3, 4]   // [1, 2, 3, 4]
[]     <|> [3, 4]   // [3, 4]

// Result — first success wins
Result<Int, Error>.failure(err) <|> .success(3)   // .success(3)
Result<Int, Error>.success(1)   <|> .success(3)   // .success(1)

// DeferredStream — second stream starts when first finishes
let a = DeferredStream<Int>.wrap(AsyncStream.just(1, 2))
let b = DeferredStream<Int>.wrap(AsyncStream.just(3, 4))
for await v in (a <|> b) { print(v) }  // 1, 2, 3, 4

// DeferredTask<A?> — race: both start concurrently, first non-nil wins, other cancelled
let primary:  DeferredTask<User?> = DeferredTask { await primaryAPI.find(id: 42) }
let fallback: DeferredTask<User?> = DeferredTask { await fallbackAPI.find(id: 42) }
let user = await (primary <|> fallback).run()

// DeferredTask<Result<A,E>> — race: both start concurrently, first .success wins
let fast: DeferredTask<Result<Data, Error>> = DeferredTask { await cdn.fetch(url) }
let slow: DeferredTask<Result<Data, Error>> = DeferredTask { await origin.fetch(url) }
let data = await (fast <|> slow).run()
```

`DeferredTask` has no `empty` (a never-resolving task would deadlock), so `<|>` is only available on the transformer variants `DeferredTask<A?>` and `DeferredTask<Result<A,E>>`. For racing two tasks with no fallback semantics, use `race`:

```swift
// race — first-to-complete wins, other is cancelled (base DeferredTask<A>)
let fastest = await race(taskA, taskB).run()
```

---

### Comonad (Extend)

A **Comonad** is the dual of a Monad. While a Monad lets you inject values (`pure`) and extract context-dependent results (`flatMap`), a Comonad lets you *extract* the current value (`extract`) and *extend* a function over the whole context (`extend` / `coflatMap`).

The `Writer` type in this library is a Comonad:

```swift
// extract — pull out the value (dual of pure)
Writer(42, ["log"]).extract   // 42

// coflatMap / extend — map a function over the entire writer context
Writer(21, ["step"]).coflatMap { w in w.value * 2 + w.log.count }
// Writer(43, ["step"])   — value: 21*2 + 1, log preserved

// duplicate — wrap the writer in another writer (dual of join)
Writer(42, ["log"]).duplicate   // Writer(Writer(42, ["log"]), ["log"])
```

#### Comonad operators _(optional, requires DataStructureOperators)_

`->>` extends a comonad (container on the left):

```swift
Writer(21, ["x"]) ->> { $0.value * 2 }   // Writer(42, ["x"])
```

`<<-` is the flipped version — function on the left:

```swift
{ $0.value * 2 } <<- Writer(21, ["x"])   // Writer(42, ["x"])
```

---

### Functional Getter / Setter for Structs (Lens)

Swift value types are immutable-by-default, which is great until you need to update a field several levels deep. The naïve approach requires unpacking the whole hierarchy:

```swift
var config = appState.config
var theme = config.theme
theme.colors.primary = .red
config.theme = theme
appState = AppState(config: config, ...)  // tedious and error-prone
```

A **Lens** solves this by pairing a getter and setter into a single composable value. It *focuses* on a specific field and lets you get, set, or transform it cleanly.

```swift
struct User { var name: String; var age: Int }

let nameLens = lens(\.name)   // Lens<User, String>

let user = User(name: "Alice", age: 30)
nameLens.get(user)                         // "Alice"
nameLens.set(user, "Bob")                  // User(name: "Bob", age: 30)
nameLens.over { $0.uppercased() }(user)    // User(name: "ALICE", age: 30)
```

For `let` properties (where `WritableKeyPath` isn't available), supply the setter manually:

```swift
struct Person { let name: String; let age: Int }

let nameLens = lens(\.name) { Person(name: $1, age: $0.age) }
```

**Composing Lenses**

The real power is composition. `>>>` chains two lenses into one that dives deeper into the structure:

```swift
struct Address { var city: String }
struct User { var address: Address; var name: String }

let addressLens = lens(\.address)   // Lens<User, Address>
let cityLens    = lens(\.city)      // Lens<Address, String>

let userCityLens = addressLens >>> cityLens  // Lens<User, String>

let user = User(address: Address(city: "New York"), name: "Alice")
userCityLens.get(user)              // "New York"
userCityLens.set(user, "London")    // User(address: Address(city: "London"), name: "Alice")
```

Lenses also compose with Prisms — see [Assembling Optics (AffineTraversal)](#assembling-optics-affinetraversal) for the full story.

#### Lens operators _(optional, requires CoreFPOperators)_

`^` lifts a `WritableKeyPath` into a `Lens` directly:

```swift
let ageLens: Lens<User, Int>    = ^\User.age
let nameLens: Lens<User, String> = ^\User.name
```

Composition works the same way with the lifted lenses:

```swift
let userCityLens = ^\User.address >>> ^\Address.city  // Lens<User, String>
```

For `let` properties, `^` returns a partial builder waiting for the setter:

```swift
let nameLens: Lens<Person, String> = (^\Person.name) { Person(name: $1, age: $0.age) }
```

`<<<` is the right-to-left version of `>>>`:

```swift
// These are equivalent:
let cityFirst = ^\User.address >>> ^\Address.city
let cityFirst2 = ^\Address.city <<< ^\User.address
```

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

A `Binding<Root>` combined with a `Lens<Root, Focus>` produces a `Binding<Focus>`:

```swift
@State var user = User(name: "Alice", age: 30)
let nameLens: Lens<User, String> = lens(\.name)

TextField("Name", text: $user[optic: nameLens])
```

See [Binding](docs/types/Binding.md) for the full bridge API.

---

### Functional Getter / Setter for Enums (Prism)

Just as a glass prism refracts a beam of white light into its constituent wavelengths — revealing all the colours hiding inside the one —, in Functional Programming a **Prism** has nothing to do with a progressive rock band album art, but instead it refracts a sum type (enum) into its individual cases, letting you focus on the one you care about. Where a `Lens` works on structs (where every field is always present), a Prism works on enums (where only one case is active at a time). It focuses on a specific case and lets you extract or construct values for that case.

It has three operations:
- `preview` — tries to extract the associated value; returns `nil` if the enum is a different case
- `review` — constructs an enum value from the focused type
- `over` — applies a transform to the focused value; leaves the structure unchanged if the case is inactive

```swift
enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
}

let circlePrism = prism(
    preview: { if case .circle(let r) = $0 { return r } else { return nil } },
    review:  Shape.circle
)

circlePrism.preview(.circle(5.0))              // Optional(5.0)
circlePrism.preview(.rectangle(3, 4))          // nil
circlePrism.review(7.0)                        // Shape.circle(7.0)
circlePrism.over { $0 * 2 }(.circle(5))       // Shape.circle(10.0)
circlePrism.over { $0 * 2 }(.rectangle(3, 4)) // Shape.rectangle(3, 4) — unchanged
```

If your enum has optional-returning computed properties, the keyPath shorthand is more concise:

```swift
extension Shape {
    var circleRadius: Double? {
        guard case .circle(let r) = self else { return nil }
        return r
    }
}

let circlePrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)
```

Prisms compose with other prisms and with lenses — see [Assembling Optics (AffineTraversal)](#assembling-optics-affinetraversal) for the full story.

#### Prism operators _(optional, requires CoreFPOperators)_

`>>>` and `<<<` work for Prism composition the same way as for Lens:

```swift
// Prism >>> Prism → Prism
let deepCasePrism = outerPrism >>> innerPrism

// Prism >>> Lens → AffineTraversal
let cityInLoggedInUser = loggedInPrism >>> ^\User.address >>> ^\Address.city
```

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

`Binding[optic: prism]` returns `Binding<A>?` — `nil` when the focused case is inactive:

```swift
@State var sheet: Sheet = .settings(Settings())

if let settingsBinding = $sheet[optic: settingsPrism] {
    SettingsView(settings: settingsBinding)
}
```

See [Binding](docs/types/Binding.md) for the full bridge API.

---

### Assembling Optics (AffineTraversal)

Assembling an `AffineTraversal` is like aligning a lens and a prism in a telescope — each brings its own focus, and together they reach deeper into a structure than either could alone. The `AffineTraversal` is the optic you get whenever a focus *may or may not exist*, combining optional extraction with structural update.

It has three operations:
- `preview` — tries to extract the focused value; returns `nil` if the focus is absent
- `set` — updates the focused value if present; leaves the structure unchanged if absent
- `over` — applies a transform to the focused value if present

**Lens `>>>` Prism → AffineTraversal**

Start with a struct and drill down to a field that is itself an enum case:

```swift
enum Shape { case circle(Double); case rectangle(Double, Double) }
struct Canvas { var shape: Shape }

let shapeLens: Lens<Canvas, Shape>    = lens(\.shape)
let circlePrism: Prism<Shape, Double> = prism(
    preview: { if case .circle(let r) = $0 { return r } else { return nil } },
    review:  Shape.circle
)

// Lens >>> Prism = AffineTraversal<Canvas, Double>
let circleRadiusTraversal = shapeLens >>> circlePrism

let canvas = Canvas(shape: .circle(5.0))
circleRadiusTraversal.preview(canvas)                      // Optional(5.0)
circleRadiusTraversal.set(canvas, 10.0)                    // Canvas(shape: .circle(10.0))
circleRadiusTraversal.over { $0 * 2 }(canvas)             // Canvas(shape: .circle(10.0))

let rectCanvas = Canvas(shape: .rectangle(3, 4))
circleRadiusTraversal.preview(rectCanvas)                  // nil
circleRadiusTraversal.set(rectCanvas, 10.0)               // Canvas(shape: .rectangle(3, 4)) — unchanged
```

**Prism `>>>` Lens → AffineTraversal**

Go the other direction: start with an enum case and drill further into the associated value:

```swift
enum App { case loggedIn(User); case guest }
struct User { var address: Address }
struct Address { var city: String }

let loggedInPrism: Prism<App, User> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review:  App.loggedIn
)
let cityLens: Lens<User, String> = lens(\.address) >>> lens(\.city)

// Prism >>> Lens = AffineTraversal<App, String>
let cityInLoggedInUser = loggedInPrism >>> cityLens

cityInLoggedInUser.preview(.loggedIn(User(address: Address(city: "Paris"))))  // Optional("Paris")
cityInLoggedInUser.preview(.guest)                                             // nil
cityInLoggedInUser.set(.loggedIn(User(address: Address(city: "Paris"))), "London")
// .loggedIn(User(address: Address(city: "London")))
```

**Building a longer pipeline**

Because all three optic types compose via `>>>`, you can chain freely:

```swift
let radiusTraversal = loggedInPrism >>> lens(\.avatar) >>> circlePrism
// AffineTraversal<App, Double>
```

`<<<` is the right-to-left version:

```swift
let radiusTraversal2 = circlePrism <<< lens(\.avatar) <<< loggedInPrism
```

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

`Binding[optic: affineTraversal]` returns `Binding<A>?` — `nil` when the focus is absent:

```swift
@State var app: App = .loggedIn(User(...))

if let cityBinding = $app[optic: loggedInPrism >>> ^\User.address >>> ^\Address.city] {
    TextField("City", text: cityBinding)
}
```

See [Binding](docs/types/Binding.md) for the full bridge API.

---

### Bidirectional Conversions (Iso)

An `Iso<S, A>` is a pair of total, invertible functions: `get: (S) -> A` and `reverseGet: (A) -> S`. Unlike a `Lens`, there is no notion of "focusing on a part" — the whole structure converts losslessly in both directions.

```swift
let metersToFeet = iso(get: { $0 * 3.28084 }, reverseGet: { $0 / 3.28084 })  // Iso<Double, Double>

metersToFeet.get(1.0)          // 3.28084
metersToFeet.reverseGet(3.28084) // 1.0
metersToFeet.reverse           // Iso<Double, Double> with get/reverseGet swapped
```

`over` applies a transform through the round-trip:

```swift
metersToFeet.over { $0 + 10 }(1.0)  // convert to feet, add 10, convert back
```

Every `Iso` is also a valid `Lens`, `Prism`, and `AffineTraversal` — use `.asLens`, `.asPrism`, or `.asAffineTraversal` to downcast when needed.

**Iso as Monoid** — endomorphism isos (`Iso<A, A>`) form a `Monoid` under composition. Use `mconcat` to chain a sequence of lossless transforms into one:

```swift
let rotate    = iso(get: rotatePoint,    reverseGet: rotatePointBack)
let scale     = iso(get: scalePoint,     reverseGet: scalePointBack)
let translate = iso(get: translatePoint, reverseGet: translatePointBack)

let transform: Iso<Point, Point> = mconcat([rotate, scale, translate])
transform.get(point)        // all three applied in order
transform.reverse.get(point) // all three reversed, in reverse order
```

#### Iso operators _(optional, requires CoreFPOperators)_

`>>>` and `<<<` compose an `Iso` with any other optic, returning the strongest optic the combination allows:

| Composition | Result |
|-------------|--------|
| `Iso >>> Iso` | `Iso` |
| `Iso >>> Lens` / `Lens >>> Iso` | `Lens` |
| `Iso >>> Prism` / `Prism >>> Iso` | `Prism` |
| `Iso >>> AffineTraversal` / `AffineTraversal >>> Iso` | `AffineTraversal` |

```swift
let addOne = iso(get: { $0 + 1 }, reverseGet: { $0 - 1 })
let timesTwo = iso(get: { $0 * 2 }, reverseGet: { $0 / 2 })

let combined = addOne >>> timesTwo  // Iso<Int, Int>
combined.get(5)          // (5+1)*2 = 12
combined.reverseGet(12)  // 12/2 - 1 = 5
```

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

`Binding[optic: iso]` always returns a `Binding<A>` (never optional — Iso is total):

```swift
@State var meters: Double = 1.0

// Editing in feet while storing in meters:
TextField("Feet", value: $meters[optic: metersToFeet], format: .number)
```

See [Binding](docs/types/Binding.md) for the full bridge API.

---

### Composing Transformations (Endo)

`Endo<A>` wraps an endomorphism — a function `(A) -> A` — and gives it a `Monoid` instance under left-to-right composition. The identity element is the do-nothing function.

```swift
let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
let lower   = Endo<String> { $0.lowercased() }
let exclaim = Endo<String> { $0 + "!" }

let normalize: Endo<String> = mconcat([trim, lower, exclaim])
normalize.runEndo("  HELLO  ")   // "hello!"
normalize("  HELLO  ")           // "hello!" — callAsFunction works too
```

`Endo.combine(f, g)` applies `f` first, then `g` — the same left-to-right order as `>>>`. The `<>` operator and `mconcat` follow from the `Semigroup`/`Monoid` conformances:

```swift
let pipeline = trim <> lower <> exclaim   // same as mconcat([trim, lower, exclaim])
pipeline("  HELLO  ")   // "hello!"
```

**`Endo` vs `Iso<A, A>`**

Both are endomorphisms and both form a `Monoid` under composition, but they differ in one key way:

| | `Endo<A>` | `Iso<A, A>` |
|---|---|---|
| Stores | `(A) -> A` | `(A) -> A` + inverse `(A) -> A` |
| Reversible | no | yes — `.reverse` gives the undo |
| Use when | trimming, clamping, normalizing | rotating, scaling, unit conversion |

You can always extract an `Endo` from an `Iso<A, A>` via `.get`, but not vice versa — invertibility requires both directions up front.

---

### SumType2 — Shared Interface for Two-Case Types

`Either`, `Result`, and similar two-case types all conform to the `SumType2<A, B>` protocol, which gives them a uniform interface without duplicating `switch` statements everywhere.

```swift
// match — exhaustive elimination without a switch
let e: Either<String, Int> = .right(42)
e.match(
    caseLeft:  { "Error: \($0)" },
    caseRight: { "Value: \($0)" }
)  // "Value: 42"

// .a / .b — optional projections
Either<String, Int>.left("oops").a   // Optional("oops")
Either<String, Int>.right(42).b      // Optional(42)

// .isA / .isB — predicate checks
Result<Int, Error>.success(42).isB   // true

// from — convert between any two conforming types with the same type parameters
let r = Result<Int, String>.from(Either<String, Int>.right(42))  // .success(42)
```

The protocol defines three requirements — `left(_:)`, `right(_:)`, `match(caseLeft:caseRight:)`, and `from(_:)` — and provides `.a`, `.b`, `.isA`, `.isB` as extensions. Use `SumType2` in your own generic functions to work over `Either`, `Result`, and any custom two-case type simultaneously.

---

### Utilities

**Function composition** — `>>>` and `<<<`

`>>>` chains functions left-to-right; `<<<` chains right-to-left. Both produce a single function from the chain:

```swift
let trim:       (String) -> String = { $0.trimmingCharacters(in: .whitespaces) }
let uppercased: (String) -> String = { $0.uppercased() }
let exclaim:    (String) -> String = { $0 + "!" }

let shout  = trim >>> uppercased >>> exclaim   // left-to-right
let shout2 = exclaim <<< uppercased <<< trim   // right-to-left — equivalent

shout("  hello  ")    // "HELLO!"
shout2("  hello  ")   // "HELLO!"
```

Key paths are also composable — useful when building point-free transformations over nested types:

```swift
struct Company { var ceo: Person }
struct Person  { var name: String }

let ceoName: (Company) -> String = \.ceo >>> \.name
companies.map(ceoName)   // [String]
```

---

**Function application** — `£` / `<|` and `|>`

`£` and `<|` both apply a function to a value with the function on the left. They use the same precedence group — lower than every other operator — so they eliminate wrapping parentheses. Both are right-associative, so chains nest naturally:

```swift
uppercased £ trim £ "  hello  "   // "HELLO" — evaluated right-to-left: trim first, then uppercased
```

The practical difference is in readability and conflict risk: `£` is a single Unicode character that never clashes with any other Swift operator. `<|` is ASCII, but the `<` and `|` characters appear in comparison and bitwise-OR operators, so it can cause parse ambiguity when placed directly adjacent to expressions involving `<` or `|`. Prefer `£` inside complex expressions; use `<|` where clarity is sufficient.

`|>` is the value-left flip — left-associative at the same level — ideal for pipelines:

```swift
"  hello  "
    |> trim
    |> uppercased
    |> exclaim   // "HELLO!"
```

---

**`id`** — identity function

`id` returns its argument unchanged. It replaces `{ $0 }` or `\.self` in any position that expects a function, enabling point-free style:

```swift
id("hello")   // "hello"

// Use instead of { $0 } in map/flatMap/filter:
[Optional(1), nil, Optional(3)].compactMap(id)   // [1, 3]
["a", "b", "c"].map(id)                          // ["a", "b", "c"] — no-op map

// Use as a default closure parameter:
func process(_ transform: (String) -> String = id) -> String { ... }

// Use in Optional.fold to pass values through the some branch unchanged:
optional.fold(onNone: "", onSome: id)
```

---

**`const`** — ignore arguments, return a fixed value

`const` produces a function that ignores all its arguments and returns a single value. It works for any number of ignored arguments thanks to parameter packs — no overloads needed:

```swift
// Single-argument: replaces { _ in 42 }
[1, 2, 3].map(const(42))                     // [42, 42, 42]
Optional("hello").map(const(true))            // Optional(true)

// Multi-argument: replaces { _, _ in "fixed" } or { _, _, _, _ in "fixed" }
let alwaysZero: (Int, String, Bool) -> Int = const(0)
alwaysZero(99, "ignored", true)              // 0

// Combine with map to replace contents:
results.map(const(.success(())))             // all successes, structure preserved
```

---

**`flip`, `curry`, `uncurry`, `partialApply`**

```swift
// flip — swap the two arguments of a binary function
flip(-)( 3, 10)           // 7    — equivalent to 10 - 3
[1, 2, 3].reduce(0, flip(+))  // sum, argument order doesn't matter for +

// curry — (A, B) -> C  into  A -> B -> C
let add = curry { (a: Int, b: Int) in a + b }
let addFive = add(5)       // (Int) -> Int
addFive(3)                 // 8

// uncurry — A -> B -> C  into  (A, B) -> C
let addUncurried = uncurry(add)
addUncurried(3, 4)         // 7

// partialApply — fix the first argument
let triple = partialApply({ a, b in a * b }, 3)
triple(7)                  // 21
```

---

**`withArg`** — select which argument to operate on in a multi-argument context

`withArg` takes a key path that picks one value from a tuple of arguments, then lets you plug a single-argument function into that position. This is useful when adapting a unary function into a binary or ternary context without a closure:

```swift
// Adapting a (String) -> Bool into (Int, String) -> Bool
// by selecting the second argument:
let isLongName: (Int, String) -> Bool = withArg(\.1)(\.count >>> { $0 > 5 })
isLongName(42, "Alexander")   // true
isLongName(42, "Ali")         // false

// Selecting the first argument explicitly:
let doubleFirst: (Int, String) -> Int = withArg(\.0)({ $0 * 2 })
doubleFirst(21, "ignored")    // 42
```

---

**`fanout`** — apply several functions to the same input

```swift
// All functions receive the same value; results are collected into a tuple:
let describe = fanout(\.count, \.first, uppercased)
let (count, first, upper) = describe("hello")
// (5, Optional("h"), "HELLO")

// Useful for building a summary from a single pass:
users.map(fanout(\.name, \.age, \.isAdmin))
// [(String, Int, Bool)]
```

---

**`join` and `void`**

`join` flattens one layer of nesting; `void` discards the contained values while keeping the container shape:

```swift
// join — one layer in, same container out
join([[1, 2], [3, 4]])                                      // [1, 2, 3, 4]
join(Optional(Optional(42)))                                // Optional(42)
join(Result<Result<Int, E>, E>.success(.success(42)))       // .success(42)

// void — like map(ignore); keeps structure, discards values
void([1, 2, 3])          // [(), (), ()]
void(Optional(42))       // Optional(())
void(Result<Int,E>.success(99))   // .success(())
```

`void` differs from `ignore`: `ignore` is `(A) -> Void` (discards a single value entirely), while `void` is `Container<A> -> Container<Void>` (maps every element to `()`). Use `ignore` when you want to drop a value; use `void` when you want to strip the values from a container but keep its structure.

---

**Tuple utilities**

```swift
mapTuple2(uppercased)("hello", "world")    // ("HELLO", "WORLD")
mapTuple3({ $0 * 2 })(1, 2, 3)           // (2, 4, 6)
tuple(1, "hello")                          // (1, "hello")
untuple { a, b in a + b }((3, 4))        // 7 — (A, B) argument → two separate arguments
```

---

**Type casting** — curried, for pipelines

```swift
// cast — identity cast; value must already be the target type (no crash)
cast(String.self)("hello")         // "hello"

// castOptionally — safe conditional cast; nil on mismatch
castOptionally(Int.self)("hello")  // nil
castOptionally(Int.self)(42)       // Optional(42)

// In a pipeline:
items.compactMap(castOptionally(URL.self))   // [URL] — only URLs survive
```

---

**`lazy` / `unlazy`** — defer and force evaluation

```swift
let later: () -> Int = lazy(expensiveComputation())   // not evaluated yet
unlazy(later)                                          // forces it
```

---

**Boolean predicates** — curried, composable, for fully tacit style

`equals`, `notEquals`, `not`, `and`, `or` are overloaded for both `Bool` values and `(A) -> Bool` predicates, so they compose directly with key paths, `<<<`/`>>>`, and `flip` to build predicates without any closure syntax:

```swift
struct User { let name: String; let age: Int; let isAdmin: Bool }

// equals / notEquals — match on a value
users.filter(equals("Alice") <<< \.name)       // only "Alice"
users.filter(notEquals("Alice") <<< \.name)    // everyone else

// not — negate any predicate
users.filter(not(\.isAdmin))                   // non-admins only

// and / or — combine predicates
users.filter(and(equals("Alice") <<< \.name, \.isAdmin))
// Alices who are also admins

users.filter(or(equals("Alice") <<< \.name, equals("Bob") <<< \.name))
// Alices or Bobs

// Deeply composed — fully tacit with flip to avoid any closure:
users.filter(and(not(\.isAdmin), flip(>=)(18) <<< \.age))

// All even positives — fully tacit:
[0, 1, 2, -1, 4].filter(and(equals(0) <<< flip(%)(2), flip(>)(0)))   // [2, 4]
```

---

**`Mutable`** — builder-pattern copy for value types

```swift
struct Config: Mutable { var host: String; var port: Int }

let base = Config(host: "localhost", port: 8080)
let dev  = base.mutate { $0.port = 3000 }     // Config(host: "localhost", port: 3000)
let prod = base.mutate { $0.host = "prod.example.com" }
```

---

**`ignore` / `absurd`** — structural helpers

```swift
// ignore — discard a value and return ()
[1, 2, 3].map(ignore)         // [(), (), ()]
tasks.forEach(ignore)          // run side effects, discard results

// absurd — exhaustively eliminate the Never type in impossible branches
func handle<A>(_ result: Either<Never, A>) -> A {
    result.match(caseLeft: absurd, caseRight: id)
}
```

---

### Operator Reference

All operators require `CoreFPOperators` (for built-in types) or `DataStructureOperators` (for `DataStructure` types). Every operator has a named-function equivalent in the core module.

| Operator | Flipped | Description | Types |
|----------|---------|-------------|-------|
| `<£>` | `<&>` | Functor map — fn left / container left | `Optional`, `Array`, `Result`, `Publisher`, `AsyncSequence`, `DeferredTask`, `DeferredStream`, `Either`, `Reader`, `Stateful`, `Validation`, `Writer` |
| `<£^>` | `<&^>` | Transformer map (nested containers) — transformer-only, no base-type overloads | `DeferredTask`, `DeferredStream`, `Either`, `Reader`, `Stateful`, `Validation`, `Writer` transformer variants |
| `£>` | `<£` | Replace contents with a constant — container left / value left | `Optional`, `Array`, `Result`, `Publisher`, `AsyncSequence`, `DeferredTask`, `DeferredStream`, `Either`, `Reader`, `Stateful`, `Validation`, `Writer` |
| `<*>` | — | Applicative apply — wrapped function on left, wrapped value on right | `Optional`, `Array`, `Result`, `Publisher`, `AsyncSequence`, `DeferredTask`, `DeferredStream`, `Either`, `Reader`, `Stateful`, `Validation`, `Writer` |
| `*>` | `<*` | Sequence two effects — keep right / keep left | `Optional`, `Array`, `Result`, `Publisher`, `AsyncSequence`, `DeferredTask`, `DeferredStream`, `Either`, `Reader`, `Stateful`, `Validation`, `Writer` |
| `>>-` | `-<<` | Monadic bind — container left / fn left | `Optional`, `Array`, `Result`, `Publisher`, `AsyncSequence`, `DeferredTask`, `DeferredStream`, `Either`, `Reader`, `Stateful`, `Writer` |
| `->>` | `<<-` | Comonad extend — container left / fn left | `Writer` |
| `>=>` | `<=<` | Kleisli composition — left-to-right / right-to-left | `Optional`, `Array`, `Result`, `DeferredTask`, `DeferredStream`, `Either`, `Reader`, `Stateful`, `Writer` |
| `>>>` | `<<<` | Function / optics composition — left-to-right / right-to-left | Functions, `Iso`, `Lens`, `Prism`, `AffineTraversal` |
| `£` / `<\|` | `\|>` | Function application — fn left / value left | Any function |
| `<\|>` | — | Alternative / choice | `Optional`, `Array`, `Result`, `Publisher`, `DeferredTask<A?>`, `DeferredTask<Result<A,E>>`, `DeferredStream` |
| `<>` | — | Semigroup append | `String`, `Array`, `Optional`, `Dictionary`, `Set`, `Result`, `Int.Monoids.*`, `Bool.Monoids.*`, `SIMD4<Int>.Monoids.*`, … |
| `++` | — | Concatenation | `String`, `Array` |
| `^` _(prefix)_ | — | Lift `WritableKeyPath` → `Lens`; `KeyPath` → partial `Lens` builder | `WritableKeyPath`, `KeyPath` |
| `^` _(infix)_ | — | Numeric power — `base ^ exp` | `SignedNumeric` |
| `±` / `+/-` | — | Symmetric range — `center ± delta` → `ClosedRange` | `SignedNumeric` |
| `≅` | — | Flipped range match — `value ≅ range` (equivalent to `range ~= value`) | `Comparable` |

---

### Types

Each type in this library has a dedicated reference page with comprehensive examples covering every operation, operator, and transformer combination.

#### CoreFP

| Type | Description |
|------|-------------|
| [Optional](docs/types/Optional.md) | Swift's built-in optional, extended with full Functor / Applicative / Monad instances |
| [Array](docs/types/Array.md) | Swift's built-in array, extended — models nondeterminism and multiple results |
| [Result](docs/types/Result.md) | Swift's built-in result, extended with `bimap`, Kleisli composition, and Monoid strategies |
| [Publisher](docs/types/Publisher.md) | Combine's `AnyPublisher`, extended with functional operations |
| [AsyncSequence](docs/types/AsyncSequence.md) | Swift's `AsyncSequence`, extended with functional operations |
| [DeferredTask](docs/types/DeferredTask.md) | Lazy async computation — nothing runs until `.run()` is called |
| [DeferredStream](docs/types/DeferredStream.md) | Lazy async stream — nothing starts until first iteration |
| [Binding](docs/types/Binding.md) | SwiftUI's `Binding`, extended with `[optic:]` subscripts for `Lens`, `Iso`, `Prism`, and `AffineTraversal` _(Apple platforms only)_ |

#### DataStructure

| Type | Description |
|------|-------------|
| [Either](docs/types/Either.md) | Unconstrained sum type — both sides are equal citizens, no `Error` requirement |
| [Validation](docs/types/Validation.md) | Accumulating applicative — errors collect instead of short-circuiting |
| [Reader](docs/types/Reader.md) | Dependency injection monad — wraps `(Environment) -> Output` |
| [Stateful](docs/types/Stateful.md) | State threading monad — wraps `(inout S) -> A` |
| [Writer](docs/types/Writer.md) | Append-as-you-go monad — produces a value alongside an accumulated log |
| [NonEmpty](docs/types/NonEmpty.md) | Statically guaranteed non-empty sequence — Semigroup (no Monoid), full FAM + Foldable + Traversable |

---

## Contributing

Contributions are welcome. The architecture has a few firm rules to keep the library consistent:

- Every operator must delegate to a named function in the core module — never implement logic directly inside an operator definition
- Every directional operator has a flipped counterpart (e.g., `<£>` ↔ `<&>`); both must be added in the same commit
- Operator modules (`CoreFPOperators`, `DataStructureOperators`) are separate SPM targets and may not use custom operators internally

To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes, including tests
4. Run the full test suite to confirm nothing is broken
5. Submit a pull request

## Testing

The library verifies functional programming laws (Functor, Applicative, Monad laws) and all operator behaviours across all types and their transformer combinations.

Test targets: `CoreFPTests`, `CoreFPOperatorsTests`, `DataStructureTests`, `DataStructureOperatorsTests`.

```bash
# Run all tests
swift test

# Run a single test target
swift test --target CoreFPTests

# Run a specific test by name (Swift Testing uses / as separator)
swift test --filter "DeferredTaskTests/flatMap"
```

## Platform Support

| Platform | Minimum Version |
|----------|----------------|
| macOS    | 10.15+         |
| iOS      | 13.0+          |
| tvOS     | 13.0+          |
| watchOS  | 6.0+           |

Combine-based features (`Publisher` extensions) require macOS 13.0+ / iOS 16.0+. All non-Combine modules are supported on Linux.

## License

MIT
