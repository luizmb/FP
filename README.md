# FP

FP is a Swift library that brings functional programming patterns to your codebase in a composable, type-safe way. It extends Swift's built-in types (`Optional`, `Result`, `Array`, `Dictionary`, `Set`, functions, Combine's `Publisher`, `AsyncSequence`/`AsyncStream`) and introduces new data structures that make common patterns — error handling, dependency injection, state threading, validation — explicit, predictable, and easy to test.

[![Tests](https://github.com/luizmb/FP/actions/workflows/ci.yml/badge.svg)](https://github.com/luizmb/FP/actions)
[![Documentation](https://img.shields.io/badge/docs-online-blue)](https://ios.lu/FP)
[![Swift 6.3+](https://img.shields.io/badge/swift-6.3%2B-orange)](https://swift.org)

**[→ Full API Documentation](https://ios.lu/FP)** · [Learning Resources](#learning-resources) · [Installation](#installation)

The library follows Haskell's semantics (`base`, `transformers`, streaming libraries): when Swift ergonomics and Haskell's laws disagree, the laws win. For example, `<*>` always equals `ap` for a monad, and a transformer stack only gets a monad where Haskell's `transformers` defines one. Names borrow from Scala Cats where Haskell's would clash with Swift. It is designed to be used incrementally: start with just the core extensions and adopt more as your comfort grows.

## Contents

- [Learning Resources](#learning-resources)
- [API Documentation](#api-documentation)
- [Installation](#installation)
  - [Modules](#modules)
    - [`FPMacros` — optic derivation via Swift macros](#fpmacros--optic-derivation-via-swift-macros-optional)
    - [`CoreFP` — the foundation](#corefp--the-foundation)
    - [`CoreFPOperators` — expressive operator sugar](#corefpoperators--expressive-operator-sugar-optional)
    - [`DataStructure` — additional functional data structures](#datastructure--additional-functional-data-structures-optional)
    - [`DataStructureOperators` — operators for data structures](#datastructureoperators--operators-for-data-structures-optional)
  - [Choosing what to import](#choosing-what-to-import)
- [Quick Start](#quick-start)
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
  - [Stacking Effects (Monad Transformers)](#stacking-effects-monad-transformers)
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
  - [Identity Optic (.id)](#identity-optic-id)
  - [Safe Collection Access ([safe:], [id:], and ix)](#safe-collection-access-safe-id-and-ix)
  - [IdentifiedArray — ordered collection with O(1) by-id access](#identifiedarray--ordered-collection-with-o1-by-id-access)
  - [Bidirectional Conversions (Iso)](#bidirectional-conversions-iso)
    - [Iso operators](#iso-operators-optional-requires-corefpoperators)
  - [Newtype — Branded Values](#newtype--branded-values)
  - [Composing Transformations (Endo)](#composing-transformations-endo)
  - [Cost-Free Mutations (EndoMut)](#cost-free-mutations-endomut)
  - [SumType2 — Shared Interface for Two-Case Types](#sumtype2--shared-interface-for-two-case-types)
  - [Concurrency: Sendable-First](#concurrency-sendable-first)
  - [Utilities](#utilities)
  - [Operator Reference](#operator-reference)
    - [Operator Precedence](#operator-precedence)
  - [Types](#types)
    - [CoreFP](#corefp)
    - [DataStructure](#datastructure)
  - [Generating Code with Macros (@Lenses, @Prisms, @ApplyOptics, @Iso, @DeriveMonoid, @Mock, @Witness)](#generating-code-with-macros-lenses-prisms-applyoptics-iso-derivemonoid-mock-witness)
  - [Property-Based Testing (Gen)](#property-based-testing-gen)
- [Coming from Haskell](#coming-from-haskell)
- [Contributing](#contributing)
- [Testing](#testing)
- [Platform Support](#platform-support)
- [License](#license)

## Learning Resources

New to functional programming? These are some of the best starting points:

- [Functors, Applicatives, and Monads in Pictures](https://mokacoding.com/blog/functor-applicative-monads-in-pictures/) — a visual, intuition-first introduction to the core concepts
- [Learn You a Haskell for Great Good!](https://learnyouahaskell.github.io/) — a beginner-friendly free book that explains the ideas behind this library

For a hands-on, interactive walkthrough, see the "Modeling Failures" tutorial and the full article catalog at **[ios.lu/FP](https://ios.lu/FP)**, which includes a runnable example for every type and function.

Using Claude Code (or another AI assistant) with this library? [`docs/claude-skills`](docs/claude-skills/README.md) has task-oriented prompt templates for both using the library (operators, Reader, Prisms, refactoring imperative code) and extending it (adding a new type, building a transformer stack).

## API Documentation

**[→ Full API Reference at ios.lu/FP](https://ios.lu/FP)**

Browse the complete API documentation with examples and tutorials for every type and function in FP, CoreFP, DataStructure, and all operator modules.

## Installation

FP is a Swift Package Manager library and is designed to be **modular**: import only what you need. Each module builds on the previous one, so you can start small and expand.

```swift-sketch
// Package.swift
dependencies: [
    .package(url: "https://github.com/luizmb/FP.git", from: "3.0.0")
]
```

### Modules

#### `FPMacros` — optic derivation via Swift macros _(optional)_

Adds `@Lenses`, `@Prisms`, `@ApplyOptics` (with the `@NoOptics` opt-out), `@Iso`, `@DeriveMonoid`, `@Mock` and `@Witness`. It is not re-exported by `FP`, so add the `FPMacros` product separately. Requires Swift 6.3+ and pulls in swift-syntax at build time.

#### `CoreFP` — the foundation

The minimum you need. Adds several functional operations to Swift's built-in types — `Optional`, `Result`, `Array`, `Dictionary`, `Set`, functions, Combine's `Publisher`, and Swift Concurrency's `AsyncSequence` and more.

#### `CoreFPOperators` — expressive operator sugar _(optional)_

Adds custom symbolic operators for all `CoreFP` types. Using operators is entirely optional — every operator has a named function equivalent in `CoreFP` — but they allow a more concise, expression-oriented style.

> **Before adding this module**, check your codebase for existing definitions of these symbols. Some (like `<>`, `>>>`, `|>`, or prefix `^`) are used in other libraries and could cause conflicts or ambiguity errors at the call site.

#### `DataStructure` — additional functional data structures _(optional)_

Adds new types that are common in functional languages but absent from Swift's standard library, such as `Either`, `Validation`, `Loading`, `These`, `NonEmpty`, `Zipper`, `IdentifiedArray`, `Reader`, `Stateful`, `Writer`, `Newtype` and `Gen`, plus most of the 74 transformer stacks (`ReaderTEither`, `StatefulTOptional`, …).

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
| Macro-derived `Lens` and `Prism` optics | `FPMacros` |

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

```swift-sketch
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "FP", package: "FP")  // or any individual module
    ]
)
```

---

## Quick Start

The fastest way to get a feel for the library: parse, validate, and transform a value in one point-free pipeline.

```swift
import FP

extension String: @retroactive Error {}  // for brevity in these examples; use a real error type in production

func parseAge(_ raw: String) -> Result<Int, String> {
    Int(raw).fold(onNone: .failure("not a number"), onSome: { .success($0) })
}

func validateAdult(_ age: Int) -> Result<Int, String> {
    age >= 18 ? .success(age) : .failure("must be 18 or older")
}

let greet: @Sendable (Int) -> String = { "Welcome! You are \($0)." }

let onboard: @Sendable (String) -> Result<String, String> = { raw in
    parseAge(raw) >>- validateAdult <&> greet
}

onboard("25")   // .success("Welcome! You are 25.")
onboard("12")   // .failure("must be 18 or older")
onboard("abc")  // .failure("not a number")
```

`>>-` is monadic bind (chains a step that can fail); `<&>` is functor map (transforms the success value once the chain has committed). See below for the full tour of every type and operator in the library.

The examples that follow share a handful of small types. They are declared once, here, and every `swift` block in this README compiles when the blocks are concatenated from top to bottom (illustrative fragments use `swift-sketch` fences instead):

```swift
struct Item: Identifiable, Sendable { let id: Int; var name: String; var views = 0 }
struct User: Identifiable, Sendable { let id: Int; var name: String }
struct Person: Sendable { var name: String; var age: Int }
struct Address: Sendable { var city: String }
enum Shape: Sendable { case circle(Double); case rectangle(Double, Double) }
struct Account: Sendable { var address: Address; var name: String; var avatar: Shape = .circle(1) }
enum App: Sendable { case loggedIn(Account); case guest }
struct Config: Sendable { var baseURL = "https://example.com" }
struct AppState: Sendable { var feed: [Item]; var counter = 0 }

// Leaf dependencies for the Reader examples
struct URLRequester: Sendable { var isReachable: Bool; var get: @Sendable (String) -> [Item] }
struct JSONParser: Sendable {}
struct DateNow: Sendable { var now: @Sendable () -> Date }
struct DispatchQueueMain: Sendable {}
```

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

This library defines a `Semigroup` protocol, implemented by `String`, `Array`, `Optional` (when `Wrapped: Semigroup`), `Dictionary`, `Set`, `Endo`, `EndoMut`, `Iso<A, A>`, and, in `DataStructure`, by `NonEmpty`, `Writer`, `Reader`, `Newtype` and `IdentifiedArray`. Numbers, `Bool` and `Result` have more than one sensible way to combine, so they get named wrappers instead (`Int.Monoids.Sum`, `Bool.Monoids.And`, `Result.Monoids.Optimistic`, …), more on those in a moment. You can also make your own types conform to it by implementing `combine`.

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

**Optional**

`Optional<A>` is a `Semigroup` when `A` is a `Semigroup`, and a `Monoid` when `A` is a `Monoid`. This matches Haskell's `Maybe` instance exactly: both present → combine the wrapped values; one nil → return the non-nil side; both nil → nil. The identity is `.none`.

```swift
let a: String? = "hello"
let b: String? = " world"

Optional<String>.combine(a, b)           // Optional("hello world") — both present: combine
Optional<String>.combine(a, .none)       // Optional("hello")       — only left present
Optional<String>.combine(.none, b)       // Optional(" world")      — only right present
Optional<String>.combine(.none, .none)   // nil
Optional<String>.identity                // nil

a <> b                                   // Optional("hello world") — operator
mconcat([a, .none, b])                   // Optional("hello world")
mconcat([.none, .none] as [String?])     // nil — identity
```

**Result**

`Result<Success, Failure>` has no canonical `Monoid` in Haskell's `base` — `Either` faces the same problem there. This library provides four explicit newtype wrappers inside `Result.Monoids` so you name your intent rather than relying on an arbitrary default (the examples use `String` as the failure type through the `extension String: Error` from the Quick Start):

| Wrapper | Bias | When both sides match |
|---|---|---|
| `Optimistic` | success wins | only successes combine; two failures keep the left; `Failure` need not be `Semigroup` |
| `OptimisticCombining` | success wins | both sides combine; identity is `.failure(Failure.identity)` |
| `Pessimistic` | failure wins | only failures combine; two successes keep the left; `Success` need not be `Semigroup` |
| `PessimisticCombining` | failure wins | both sides combine; identity is `.success(Success.identity)` |

```swift
typealias R = Result<String, String>

// Optimistic — success wins; failures fall through; two failures keep the left
R.Monoids.Optimistic(.success("hello")) <> R.Monoids.Optimistic(.success(" world"))  // .success("hello world")
R.Monoids.Optimistic(.success("hello")) <> R.Monoids.Optimistic(.failure("oops"))    // .success("hello")
R.Monoids.Optimistic(.failure("e1"))    <> R.Monoids.Optimistic(.failure("e2"))      // .failure("e1")

// OptimisticCombining — success wins; both sides combine when matching; Monoid
R.Monoids.OptimisticCombining(.success("hello")) <> R.Monoids.OptimisticCombining(.success(" world"))  // .success("hello world")
R.Monoids.OptimisticCombining(.failure("bad"))   <> R.Monoids.OptimisticCombining(.failure(" stuff"))  // .failure("bad stuff")
R.Monoids.OptimisticCombining.identity                                                                   // .failure("") — Failure.identity

// Pessimistic — failure wins; successes fall through; two successes keep the left
R.Monoids.Pessimistic(.failure("bad")) <> R.Monoids.Pessimistic(.failure(" stuff"))  // .failure("bad stuff")
R.Monoids.Pessimistic(.failure("bad")) <> R.Monoids.Pessimistic(.success("ok"))      // .failure("bad")
R.Monoids.Pessimistic(.success("ok"))  <> R.Monoids.Pessimistic(.success("ok2"))     // .success("ok")

// PessimisticCombining — failure wins; both sides combine when matching; Monoid
R.Monoids.PessimisticCombining(.success("hello")) <> R.Monoids.PessimisticCombining(.success(" world"))  // .success("hello world")
R.Monoids.PessimisticCombining(.failure("bad"))   <> R.Monoids.PessimisticCombining(.success("ok"))      // .failure("bad")
R.Monoids.PessimisticCombining.identity                                                                    // .success("") — Success.identity

// mconcat is available for the two Monoid variants (OptimisticCombining / PessimisticCombining)
mconcat([
    R.Monoids.OptimisticCombining(.success("hello")),
    R.Monoids.OptimisticCombining(.failure("oops")),
    R.Monoids.OptimisticCombining(.success(" world")),
])  // .success("hello world") — successes win and combine
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

This library also provides `fmap` as a static, curried function, which is useful for point-free composition:

```swift
Optional<Int>.fmap { $0 * 2 }(Optional(5))  // Optional(10)
```

(`[Int].fmap`, `Result.fmap`, `Reader.fmap` and friends follow the same shape.)

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
struct Dependencies: Sendable {
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
Array.zip([1, 2, 3], ["a", "b", "c"])       // [(1, "a"), (2, "b"), (3, "c")]
Optional.zip(Optional(1), Optional(2))      // Optional((1, 2))
Optional.zip(Optional(1), Optional<Int>.none)   // nil — one nil means the pair is nil
```

For `Array`, `zip` pairs elements by index (the shorter array wins). For `Optional`, both values must be present for anything to come out. For `Publisher`, it waits until both have emitted and pairs them as they arrive (`zip` is a named function there; `<*>` on `Publisher` is not zip, see below).

Note: `zip` on `Array`, `Publisher` and `AsyncStream` is positional pairing (a `ZipList`-style operation), *not* the applicative of those types. Their `<*>` is cartesian (see below).

`Result` doesn't have a stdlib `zip`, but this library adds it:

```swift
Result.zip(Result<Int, String>.success(1), Result<Int, String>.success(2))   // .success((1, 2))
Result.zip(Result<Int, String>.success(1), Result<Int, String>.failure("!")) // .failure("!")
```

**Apply**

Apply is a related operation: what if the *function itself* is inside a container? `apply` unwraps both the function and the value, applies the function, and wraps the result back up:

```swift
Optional<Int>.apply({ $0 * 2 }, Optional(3))   // Optional(6)
Optional<Int>.apply(nil, Optional(3))          // nil
```

For `Array`, apply gives every combination — each function applied to every value:

```swift
[Int].apply([{ $0 + 1 }, { $0 * 10 }], [1, 2])  // [2, 3, 10, 20]
```

`Publisher` behaves the same way: its `apply` / `<*>` is derived from its ordered-concat bind, so each function runs over the whole value stream, in order. Use `zip` for pairwise combination. `AsyncStream` is the same (`<*>`, `liftA2`, `*>` and `<*` are derived from its ordered-concat bind). Because an `AsyncStream` is single-pass, the right-hand stream is drained once into a buffer (`AsyncStream.replayable(_:)`) and replayed for each left element, so it must be finite. `[1, 2] *> [a, b]` yields `a, b, a, b`, and `[1, 2] <* [a, b]` yields `1, 1, 2, 2`. To pair positionally use `AsyncStream.zip(a, b)`.

The relationship between `zip` and `apply`: for `Optional`, `Result`, `Either`, `Validation`, `Reader`, `Stateful`, `Writer` and `Loading`, `zip(a, b)` equals `liftA2({ ($0, $1) })(a, b)`, so `apply` is `zip` followed by `map`: first zip the function-container with the value-container to get pairs, then map `{ (fn, value) in fn(value) }` over the pairs. For `Array`, `Publisher` and `AsyncStream` it is not like that. Their `zip` is positional pairing, a separate function, while `apply` / `<*>` is the cartesian applicative derived from bind (`[f, g] <*> [1, 2] == [f(1), f(2), g(1), g(2)]`).

Types that support `apply` are called **Applicatives**. Every Monad is an Applicative, but not vice versa — Applicatives can't express sequential dependencies between steps (you'll need `flatMap` for that).

**Parallel execution**

`zip` and `apply` take *independent* effects (the second doesn't need the first's value), but in this library `apply` / `<*>` / `liftA2` / `*>` / `<*` on a type that is also a monad are derived from its bind (`<*> == ap`, as in Haskell), so they run left to right and stop at the first failure. Only the named `zip` on `Publisher` and `AsyncStream` subscribes to both sides concurrently and pairs positionally. Use `zip` for concurrency and pairing, `<*>` for the lawful applicative, and `flatMap` when step two needs the value from step one.

#### Applicative operators _(optional, requires CoreFPOperators)_

`<*>` applies a wrapped function to a wrapped value (function container on the left):

```swift
let plus41: @Sendable (Int) -> Int = { $0 + 41 }
let double: @Sendable (Int) -> Int = { $0 * 2 }
let triple: @Sendable (Int) -> Int = { $0 * 3 }

Optional(plus41) <*> Optional(1)                                                 // Optional(42)
[double, triple] <*> [1, 2]                                                      // [2, 4, 3, 6]
Result<@Sendable (Int) -> Int, String>.success(double) <*> Result<Int, String>.success(21)   // .success(42)
Just(plus41).eraseToAnyPublisher() <*> Just(41).eraseToAnyPublisher()
```

`*>` sequences two effects and keeps the *right* result — the left effect still runs, but its value is discarded:

```swift
Optional(42) *> Optional("hello")   // Optional("hello") — 42 ran, but only "hello" survives
[1, 2] *> ["a", "b"]               // ["a", "b", "a", "b"]
Result<Int, String>.success(42) *> Result<String, String>.success("hello")  // .success("hello")
```

`<*` keeps the *left* result instead:

```swift
Optional("hello") <* Optional(42)               // Optional("hello")
["a", "b"] <* [1, 2]                            // ["a", "a", "b", "b"]
Result<String, String>.success("hello") <* Result<Int, String>.success(42)   // .success("hello")
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

```swift-sketch
func flatMap<B>(_ transform: (A) -> Container<B>) -> Container<B>
```

But what it *does* depends entirely on the container — the same structure solves a different problem for each type.

**Optional** — failure propagation

Each step can fail, and the chain stops at the first `nil`:

```swift
func findUser(id: Int) -> User? { id == 42 ? User(id: 42, name: "Ada") : nil }
func findAddress(user: User) -> Address? { Address(city: "London") }
func city(from address: Address) -> String? { address.city }

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

**Publisher** — async sequencing

The second effect can't start until the first finishes and provides its value:

```swift
func fetchUser(id: Int) -> AnyPublisher<User, Never> { Just(User(id: id, name: "Ada")).eraseToAnyPublisher() }
func fetchPermissions(for user: User) -> AnyPublisher<[String], Never> { Just(["read"]).eraseToAnyPublisher() }
func loadDashboard(permissions: [String]) -> AnyPublisher<String, Never> { Just("dashboard").eraseToAnyPublisher() }

fetchUser(id: 42) >>- fetchPermissions >>- loadDashboard
```

Unlike `zip`, the library's bind is serial: each inner publisher runs to completion, in upstream order, before the next starts. Step two *depends on* the result of step one, and that's exactly when you reach for bind.

This library's `Publisher` bind (`bind`, `>>-`, `>=>`) is **ordered concat**, like Haskell streaming libraries: each inner publisher runs to completion, in upstream order, and no upstream value is dropped. Combine's own `flatMap` merges inner publishers concurrently; reach for it (or `switchToLatest`) when that's what you want.

#### Monad operators _(optional, requires CoreFPOperators)_

`>>-` is bind with the container on the left — same argument order as `flatMap`:

```swift
Optional("42") >>- { Int($0) }                          // Optional(42)
[1, 2] >>- { [$0, $0 * 10] }                            // [1, 10, 2, 20]
Result<String, String>.success("2") >>- { Result<Int, String>.success(Int($0) ?? 0) } // .success(2)
Just(42).eraseToAnyPublisher() >>- { Just($0 * 2).eraseToAnyPublisher() }
```

`-<<` is the flipped version — function on the left, container on the right:

```swift
{ Int($0) } -<< Optional("42")   // Optional(42)
```

`>=>` composes two "Kleisli arrows" — functions that return containers — into one:

```swift
func parseInt(_ raw: String) -> Int? { Int(raw) }
func doubleIt(_ n: Int) -> Int? { .some(n * 2) }

let parseAndDouble = parseInt >=> doubleIt
parseAndDouble("21")   // Optional(42)
parseAndDouble("xx")   // nil
```

This is function composition for container-returning functions. `<<<` and `>>>` compose regular functions; `>=>` and `<=<` compose Kleisli arrows.

`<=<` is the right-to-left version:

```swift
let parseAndDouble2 = doubleIt <=< parseInt
```

**`fanout` — apply one input to many functions.** `fanout` runs several functions that share an input type
and collects the results into a tuple (n-ary, via parameter packs). Key path literals work directly, since
they convert to `@Sendable` getters:

```swift
let bounds: @Sendable ([Int]) -> (Int?, Int?) = fanout(\.first, \.last)
bounds([9, 3, 5, 1, 16])   // (9, 16)
```

A frequent use is narrowing a big value into a smaller one whose `init` takes the parts as separate
arguments — e.g. a feature's `Environment` from a `World`. Because Swift (SE-0110) treats a tuple argument
and a multi-argument parameter list as distinct types, there are two point-free spellings:

```swift
struct World: Sendable { var badge: Int; var save: Int }
struct Env: Sendable { let badge: Int; let save: Int }

// A variadic `>>>` overload bridges the fanout tuple to the multi-argument init:
let a: @Sendable (World) -> Env = fanout(\.badge, \.save) >>> Env.init

// Symbol-free, one call — `fanout(keypaths:into:)` (key paths are constrained to `Sendable`):
let b: @Sendable (World) -> Env = fanout(keypaths: \.badge, \.save, into: Env.init)
```

The variadic `>>>` coexists with the single-argument overload without ambiguity, and the mirror `<<<` works
too (`Env.init <<< fanout(\.badge, \.save)`).

---

### Stacking Effects (Monad Transformers)

A `Reader<Config, [User]>` is a Reader, so `map` on it sees the whole array. When you want to work
on each `User` while keeping both effects, wrap it in its transformer stack: every combination is
its own struct named `OuterTInner` (`ReaderTArray`, `StatefulTEither`, `PublisherTOptional`, … 74
of them), with the usual `map` / `apply` / `flatMap` and the same operators as everything else.

```swift
import FP

let loadUsers: Reader<Config, [Person]> = Reader { _ in [Person(name: "Ada", age: 36)] }

let names = loadUsers.readerT      // ReaderTArray<Config, Person> (or ReaderTArray(loadUsers))
    .map(get(\Person.name))        // maps each person, inside the Reader
names.rawValue                     // back to Reader<Config, [String]>

struct Session: Sendable {}
struct AuthError: Error, Sendable {}
struct Token: Sendable { var value: String }

let current = Stateful<Session, Either<AuthError, Token>> { _ in .right(Token(value: "t")) }
let refreshIfExpired: @Sendable (Token) -> StatefulTEither<Session, AuthError, Token> = { token in
    Stateful<Session, Either<AuthError, Token>> { _ in .right(token) }.statefulT
}
let checked = current.statefulT >>- refreshIfExpired   // StatefulTEither<Session, AuthError, Token>
```

Lift with the property named after the outer type (`readerT`, `statefulT`, `writerT`, `publisherT`,
`asyncStreamT`, `arrayT`, `optionalT`, `resultT`, `eitherT`, `validationT`, `nonEmptyT`) or the
initialiser, leave with `.rawValue`, and for anything the stack doesn't proxy use the Haskell-named
escape hatch (`mapReaderT`, `mapStateT`, `mapPublisherT`, `mapMaybeT`, `mapExceptT`, `mapWriterT`, …),
which hands you the whole nested value (for example `stack.mapPublisherT { $0.receive(on: queue).eraseToAnyPublisher() }`).
Every stack conforms to `TransformerStack` (`rawValue`, `init(rawValue:)`, `init(_:)`; it mirrors
`RawRepresentable` without refining it), and the stacks with a lawful monad also conform to `MonadT`,
where `I` is the inner layer. The rest conform only to `TransformerStack` and stop at applicative:
every stack with `Validation` on either layer (`ValidationT*`, `EitherTValidation`, `ReaderTValidation`,
`StatefulTValidation`, `WriterTValidation`), a list inside a non-commutative effect (`EitherTArray`,
`EitherTNonEmpty`, `StatefulTArray`, `StatefulTNonEmpty`, `WriterTArray`, `WriterTNonEmpty`,
`PublisherTArray`, `AsyncStreamTArray`), `Writer` outside another monad (`WriterTReader`,
`WriterTStateful`, `WriterTPublisher`, `WriterTAsyncStream`), a monad outside `Stateful`
(`ArrayTStateful`, `OptionalTStateful`, `ResultTStateful`, `EitherTStateful`, `PublisherTStateful`),
and `Stateful` outside `Reader` or streams (`StatefulTReader`, `StatefulTPublisher`,
`StatefulTAsyncStream`). `AsyncStreamTStateful` is functor-only. The full matrix and the reasons are in the
[Monad Transformers](Sources/FP/FP.docc/Articles/MonadTransformers.md) article.

**Upgrading from 2.x:** operator overloads on nested shapes were removed, and a nested value is now just its outer type. Some old call sites still compile with a different meaning: `*>` on a `Stateful<S, Either<L, A>>` is now `Stateful`'s `*>` (it no longer skips the right side on `.left`), and `<£>` / `>>-` / `£>` on a `Reader<E, [A]>` act on the whole array. Search for `<£>`, `<&>`, `£>`, `<£`, `<*>`, `*>`, `<*`, `>>-`, `-<<`, `>=>`, `<=<` applied to nested values and wrap them in their stack (`.readerT`, `.statefulT`, …). See the CHANGELOG migration table.

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
let safeParse: @Sendable (String) -> Int = { Int($0) } >>> Optional<Int>.fold(onNone: -1, onSome: id)

// foldMap — map each element to a Monoid, then combine them
Optional(3).foldMap { Int.Monoids.Sum($0) }        // Sum(3)
(nil as Int?).foldMap { Int.Monoids.Sum($0) }      // Sum(0)  — identity

[Int].foldMap { Int.Monoids.Sum($0) }([1, 2, 3])   // Sum(6)

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
enum MyError: Error, Sendable { case err }

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
Result<Int, MyError>.failure(.err) <|> .success(3)   // .success(3)
Result<Int, MyError>.success(1)     <|> .success(3)   // .success(1)

// Either: first right wins
Either<String, Int>.left("no") <|> .right(3)   // .right(3)

// Validation is `Alt` (there is no `empty`): when both fail, the failures accumulate with `<>`
Validation<[String], Int>.failure(["a"]) <|> .failure(["b"])   // .failure(["a", "b"])
Validation<[String], Int>.failure(["a"]) <|> .success(3)       // .success(3)
```

---

### Accumulating Errors (Validation)

`Validation<E, A>` is an applicative that does *not* short-circuit: when several checks fail, the errors are combined with the `Semigroup` of `E`. It deliberately has no monad (a monad would have to stop at the first failure). `<|>` is its `Alt`: when both sides fail, both failures accumulate with `<>`.

```swift
let name: Validation<[String], String> = .failure(["name is empty"])
let age: Validation<[String], Int> = .failure(["age is negative"])

Validation<[String], Person>.liftA2({ Person(name: $0, age: $1) })(name, age)
// .failure(["name is empty", "age is negative"])

Validation(Either<[String], Int>.right(1))   // .success(1), converts from Either
```

---

### Loading State (Loading)

`Loading<Success, Failure>` models `idle` / `loading` / `loaded` / `failed`, where `loading` and `failed` can carry the previous value. `Failure` can be any `Sendable` type (a `String`, a view struct), not only an `Error`. `loadedOrPrevious` keeps a view showing the last good value, `catch` receives `(Failure, Success?)`, and `pessimisticCombine` is the "failed beats loading beats idle" combination for UI (the applicative `<*>` / `zip` is the lawful left-biased one).

```swift
let state: Loading<[Item], String> = .failed(error: "offline", previous: [Item(id: 1, name: "A")])

state.loadedOrPrevious                                      // Optional([Item(id: 1, name: "A", views: 0)])
state.catch { _, previous in Loading<[Item], String>.loading(previous: previous) }  // retry, keep stale data
Loading<(Int, Int), String>.pessimisticCombine(Loading<Int, String>.loading(previous: nil), Loading<Int, String>.failed(error: "x", previous: nil))
// .failed(error: "x", previous: nil)
```

---

### Comonad (Extend)

A **Comonad** is the dual of a Monad. A Monad lets you put a value in a context (`pure`) and chain context-producing steps (`flatMap`); a Comonad lets you *extract* the value in focus (`extract`, dual of `pure`) and *extend* a context-consuming function over the whole structure (`extend` / `coflatMap`, dual of `flatMap`; `duplicate` is the dual of `join`).

`Writer`, `NonEmpty`, `Zipper` and `Reader` (when `Environment: Monoid`, Haskell's `Traced`) are Comonads. `Writer` is shown here:

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

```swift-sketch
var config = appState.config
var theme = config.theme
theme.colors.primary = .red
config.theme = theme
appState = AppState(config: config, ...)  // tedious and error-prone
```

A **Lens** solves this by pairing a getter and setter into a single composable value. It *focuses* on a specific field and lets you get, set, or transform it cleanly.

```swift
let nameLens: Lens<Person, String> = lens(\.name)

let person = Person(name: "Alice", age: 30)
nameLens.get(person)                         // "Alice"
nameLens.set(person, "Bob")                  // Person(name: "Bob", age: 30)
nameLens.over { $0.uppercased() }(person)    // Person(name: "ALICE", age: 30)
```

For `let` properties (where `WritableKeyPath` isn't available), supply the setter manually:

```swift
struct FrozenPerson { let name: String; let age: Int }

let nameLens: Lens<FrozenPerson, String> = lens(\.name) { FrozenPerson(name: $1, age: $0.age) }
```

**Composing Lenses**

The real power is composition. `>>>` chains two lenses into one that dives deeper into the structure:

```swift
let addressLens: Lens<Account, Address> = lens(\.address)
let cityLens: Lens<Address, String>     = lens(\.city)

let userCityLens = addressLens >>> cityLens  // Lens<Account, String>

let user = Account(address: Address(city: "New York"), name: "Alice")
userCityLens.get(user)              // "New York"
userCityLens.set(user, "London")    // Account(address: Address(city: "London"), name: "Alice")
```

Lenses also compose with Prisms — see [Assembling Optics (AffineTraversal)](#assembling-optics-affinetraversal) for the full story.

**`compose` — operator-free composition** _(CoreFP only, no operators needed)_

If you import only `CoreFP` and not `CoreFPOperators`, use the `compose` method instead of `>>>`:

```swift
let userCityLens = lens(\Account.address).compose(lens(\Address.city))  // Lens<Account, String>
```

Every optic `>>>` / `<<<` overload (Lens, Prism, AffineTraversal, Iso, Traversal) delegates to `compose`, so the two forms are identical at runtime.

**`lift` — in-place mutation with `EndoMut`**

`over` returns a new `S` — it always copies. When `S` contains a large CoW buffer (an `Array`, `Dictionary`, etc.), even touching one element triggers an O(n) heap copy.

`lift` converts an `EndoMut<A>` (an in-place mutation of the focused value) into an `EndoMut<S>` (an in-place mutation of the whole) without copying `S`:

```swift
let ageReducer = EndoMut<Int> { $0 += 1 }
let personReducer: EndoMut<Person> = lens(\Person.age).lift(ageReducer)

var person = Person(name: "Alice", age: 30)
personReducer(&person)   // person.age is now 31 — zero copies of Person
```

For `WritableKeyPath`-backed lenses (those created with `lens(\.property)`), the entire operation is zero-copy — Swift's modify coroutine provides direct `inout` access to the field. For manually constructed lenses the focused value is copied once; `S` itself is never CoW-copied. See [Lifting `EndoMut` through optics](#lifting-endomut-through-optics) for the full story.

**Identity lens**

`Lens<A, A>.id` is the lens where the whole and the part are the same — get returns the value unchanged, set replaces it entirely:

```swift
Lens<Int, Int>.id.get(42)       // 42
Lens<Int, Int>.id.set(0, 42)    // 42
```

It serves as the neutral element for lens composition: `anyLens >>> Lens<A, A>.id == anyLens`.

#### Lens operators _(optional, requires CoreFPOperators)_

`^` lifts a `WritableKeyPath` into a `Lens` directly:

```swift
let ageLens: Lens<Person, Int>     = ^\Person.age
let nameLens: Lens<Person, String> = ^\Person.name
```

Composition works the same way with the lifted lenses:

```swift
let userCityLens = ^\Account.address >>> ^\Address.city  // Lens<Account, String>
```

For `let` properties, `^` returns a partial builder waiting for the setter:

```swift
let nameLens: Lens<FrozenPerson, String> = (^\FrozenPerson.name) { FrozenPerson(name: $1, age: $0.age) }
```

`<<<` is the right-to-left version of `>>>`:

```swift
// These are equivalent:
let cityFirst = ^\Account.address >>> ^\Address.city
let cityFirst2 = ^\Address.city <<< ^\Account.address
```

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

A `Binding<Root>` combined with a `Lens<Root, Focus>` produces a `Binding<Focus>`:

```swift-sketch
@State var user = Person(name: "Alice", age: 30)
let nameLens: Lens<Person, String> = lens(\.name)

TextField("Name", text: $user[optic: nameLens])
```

See [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) for the full bridge API.

---

### Functional Getter / Setter for Enums (Prism)

Just as a glass prism refracts a beam of white light into its constituent wavelengths — revealing all the colours hiding inside the one —, in Functional Programming a **Prism** has nothing to do with a progressive rock band album art, but instead it refracts a sum type (enum) into its individual cases, letting you focus on the one you care about. Where a `Lens` works on structs (where every field is always present), a Prism works on enums (where only one case is active at a time). It focuses on a specific case and lets you extract or construct values for that case.

It has three operations:
- `preview` — tries to extract the associated value; returns `nil` if the enum is a different case
- `review` — constructs an enum value from the focused type
- `over` — applies a transform to the focused value; leaves the structure unchanged if the case is inactive

```swift
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

**`set`**

`set` replaces the focused associated value if the prism matches the current case; it is a no-op otherwise:

```swift
let circlePrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)

circlePrism.set(.circle(3.14), 5.0)       // Shape.circle(5.0)
circlePrism.set(.rectangle(1, 2), 5.0)    // Shape.rectangle(1, 2) — unchanged
```

**Identity prism**

`Prism<A, A>.id` is the prism where preview always succeeds and review is the identity:

```swift
Prism<Int, Int>.id.preview(42)   // Optional(42)
Prism<Int, Int>.id.review(42)    // 42
```

**`lift` — in-place mutation with `EndoMut`**

Like `Lens.lift`, `Prism.lift` converts an `EndoMut<A>` into an `EndoMut<S>`. When the prism doesn't match the current case, the resulting `EndoMut` is a no-op and `S` is left unchanged:

```swift
let circlePrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)
let doubleRadius = EndoMut<Double> { $0 *= 2 }
let shapeReducer: EndoMut<Shape> = circlePrism.lift(doubleRadius)

var shape = Shape.circle(5.0)
shapeReducer(&shape)   // Shape.circle(10.0)

var rect = Shape.rectangle(3, 4)
shapeReducer(&rect)    // Shape.rectangle(3, 4) — no-op, no copies
```

Because Swift has no `inout` access to enum case values, the associated value is always copied once. The outer `Shape` (or whatever `S` is) is kept `inout` and is never CoW-copied.

Prisms compose with other prisms and with lenses — see [Assembling Optics (AffineTraversal)](#assembling-optics-affinetraversal) for the full story.

#### Prism operators _(optional, requires CoreFPOperators)_

`>>>` and `<<<` work for Prism composition the same way as for Lens:

```swift
let loggedInPrism: Prism<App, Account> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review:  App.loggedIn
)

// Prism >>> Lens → AffineTraversal
let cityInLoggedInUser = loggedInPrism >>> ^\Account.address >>> ^\Address.city
```

(Prism `>>>` Prism gives a `Prism` the same way.)

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

`Binding[optic: prism]` returns `Binding<A>?` — `nil` when the focused case is inactive:

```swift-sketch
@State var sheet: Sheet = .settings(Settings())

if let settingsBinding = $sheet[optic: settingsPrism] {
    SettingsView(settings: settingsBinding)
}
```

See [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) for the full bridge API.

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
let loggedInPrism: Prism<App, Account> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review:  App.loggedIn
)
let cityLens: Lens<Account, String> = lens(\Account.address) >>> lens(\Address.city)

// Prism >>> Lens = AffineTraversal<App, String>
let cityInLoggedInUser = loggedInPrism >>> cityLens

let paris = Account(address: Address(city: "Paris"), name: "Ann")
cityInLoggedInUser.preview(.loggedIn(paris))   // Optional("Paris")
cityInLoggedInUser.preview(.guest)             // nil
cityInLoggedInUser.set(.loggedIn(paris), "London")
// .loggedIn(Account(address: Address(city: "London"), name: "Ann"))
```

**Building a longer pipeline**

Because all three optic types compose via `>>>`, you can chain freely:

```swift
let loggedInPrism: Prism<App, Account> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review:  App.loggedIn
)
let circlePrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)

let radiusTraversal = loggedInPrism >>> lens(\Account.avatar) >>> circlePrism
// AffineTraversal<App, Double>
```

`<<<` is the right-to-left version:

```swift
let loggedInPrism: Prism<App, Account> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review:  App.loggedIn
)
let circlePrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)

let radiusTraversal2 = circlePrism <<< lens(\Account.avatar) <<< loggedInPrism
```

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

`Binding[optic: affineTraversal]` returns `Binding<A>?` — `nil` when the focus is absent:

```swift-sketch
@State var app: App = .loggedIn(Account(address: Address(city: "Paris"), name: "Ann"))

if let cityBinding = $app[optic: loggedInPrism >>> ^\Account.address >>> ^\Address.city] {
    TextField("City", text: cityBinding)
}
```

See [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) for the full bridge API.

**`affineTraversal` from a `WritableKeyPath` to an optional**

When a stored property is itself optional, a `WritableKeyPath<S, A?>` already captures both get and set — lift it directly into an `AffineTraversal`:

```swift
struct Profile { var nickname: String? }

let nicknameFocus = affineTraversal(\Profile.nickname)  // AffineTraversal<Profile, String>
nicknameFocus.preview(Profile(nickname: "ace"))          // Optional("ace")
nicknameFocus.preview(Profile(nickname: nil))            // nil
nicknameFocus.set(Profile(nickname: nil), "ace")         // Profile(nickname: nil) (no-op, the focus is absent)
nicknameFocus.set(Profile(nickname: "x"), "ace")         // Profile(nickname: Optional("ace"))
```

If you want "set even when nil", use `lens(\Profile.nickname)` instead (a `Lens<Profile, String?>`).

For concrete collection types this is the subscript form of `ix`:

```swift
affineTraversal(\[Int][safe: 2])   // identical to [Int].ix(2)
```

**`lift` — in-place mutation with `EndoMut`**

`AffineTraversal.lift` works the same way as `Lens.lift` and `Prism.lift`. When the focus is absent the resulting `EndoMut` is a no-op:

```swift
let circleRadiusTraversal = lens(\Canvas.shape) >>> prism(\.circleRadius, review: Shape.circle)
let scaleRadius = EndoMut<Double> { $0 *= 2 }
let canvasReducer: EndoMut<Canvas> = circleRadiusTraversal.lift(scaleRadius)

var canvas = Canvas(shape: .circle(5.0))
canvasReducer(&canvas)   // Canvas(shape: .circle(10.0))
```

The copy cost depends on which optic sits at each link of the chain. See [Lifting `EndoMut` through optics](#lifting-endomut-through-optics) for the full breakdown.

---

### Identity Optic (`.id`)

Every optic type has a static `.id` property constrained to `S == A` — the optic where the whole and the part are the same type. These are the neutral elements for composition.

```swift
Lens<Int, Int>.id.get(42)              // 42
Lens<Int, Int>.id.set(0, 42)           // 42

Prism<Int, Int>.id.preview(42)         // Optional(42)
Prism<Int, Int>.id.review(42)          // 42

AffineTraversal<Int, Int>.id.preview(42)  // Optional(42)
AffineTraversal<Int, Int>.id.set(0, 42)   // 42

Iso<Int, Int>.id.get(42)              // 42
Iso<Int, Int>.id.reverseGet(42)       // 42
Iso<Int, Int>.id.asLens               // equivalent to Lens<Int, Int>.id
```

`Iso<A, A>.id` is the strongest — it downcasts to all weaker forms via `.asLens`, `.asPrism`, `.asAffineTraversal`.

---

### Safe Collection Access (`[safe:]`, `[id:]`, and `ix`)

#### `[safe:]` — bounds-safe subscript

Collections gain a `[safe:]` subscript that returns `Element?` instead of crashing on out-of-bounds access. For `MutableCollection` the setter is available and is a no-op when the index is out of bounds or the new value is `nil`:

```swift
let xs = [10, 20, 30]
xs[safe: 1]          // Optional(20)
xs[safe: 9]          // nil

var ys = [10, 20, 30]
ys[safe: 1] = 99     // [10, 99, 30]
ys[safe: 9] = 99     // no-op — out of bounds
ys[safe: 1] = nil    // no-op — nil is ignored
```

#### `[id:]` — identity-keyed subscript

Collections of `Identifiable` elements gain an `[id:]` subscript that returns the first element whose `id` matches, or `nil`. For `RangeReplaceableCollection` (`Array`, `ArraySlice`, `ContiguousArray`) the setter is available with `Dictionary`-style add/remove semantics:

```swift
let users = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
users[id: 2]   // Optional(User(id: 2, name: "Bob"))
users[id: 9]   // nil

var roster = users
roster[id: 2] = User(id: 2, name: "Robert")  // replace in place
roster[id: 3] = User(id: 3, name: "Carol")   // append to end (id not found)
roster[id: 1] = nil                          // remove
roster[id: 9] = nil                          // no-op (not present)
roster[id: 2] = User(id: 99, name: "X")      // no-op (id-mismatch guard)
```

Setter dispatch table:

| `newValue`           | existing match | result            |
|----------------------|:---:|---------------------------|
| `nil`                | yes | remove                    |
| `nil`                | no  | no-op                     |
| `v` where `v.id ==id`| yes | replace in place          |
| `v` where `v.id ==id`| no  | append to end             |
| `v` where `v.id !=id`| —   | no-op (id-mismatch guard) |

The id-mismatch guard protects against accidental swaps — assigning an element whose `id` doesn't match the subscript key is almost always a bug. Lookup is linear (`first(where:)` / `firstIndex(where:)`); for hot paths with large collections, reach for [`IdentifiedArray`](#identifiedarray--ordered-collection-with-o1-by-id-access) (below), which keeps order *and* gives O(1) by-id access.

The setter requires `RangeReplaceableCollection` because the add/remove cases must change the collection's count — `MutableCollection` alone can only replace in place. `Array` and its slice variants cover the practical targets.

#### `ix` — collection `AffineTraversal`

`ix` lifts safe element access into an `AffineTraversal`, making it composable with the rest of the optics pipeline. It is a static method on the collection type so the compiler always knows which collection is being addressed.

**By integer index** — any `MutableCollection`:

```swift
[Int].ix(1).preview([10, 20, 30])           // Optional(20)
[Int].ix(9).preview([10, 20, 30])           // nil
[Int].ix(1).set([10, 20, 30], 99)           // [10, 99, 30]
[Int].ix(0).over({ $0 * 2 })([10, 20, 30]) // [20, 20, 30]
```

**By `Identifiable` ID** — `MutableCollection where Element: Identifiable`:

```swift
let items = [Item(id: 1, name: "A"), Item(id: 2, name: "B")]

[Item].ix(id: 2).preview(items)?.name                              // "B"
[Item].ix(id: 2).set(items, Item(id: 2, name: "Z")).map(\.name)   // ["A", "Z"]
[Item].ix(id: 99).set(items, Item(id: 99, name: "X"))             // items — no-op
```

**By dictionary key** — `Dictionary`:

```swift
let dict = ["a": 1, "b": 2]
[String: Int].ix(key: "b").preview(dict)          // Optional(2)
[String: Int].ix(key: "z").preview(dict)          // nil
[String: Int].ix(key: "b").set(dict, 99)          // ["a": 1, "b": 99]
[String: Int].ix(key: "z").set(dict, 99)          // dict — no-op (key absent)
```

**Composing `ix` with other optics**

Because `ix` returns an `AffineTraversal` it slots into any `>>>` pipeline:

```swift
struct Team { var members: [Item] }

let items = [Item(id: 1, name: "A"), Item(id: 2, name: "B")]

// AffineTraversal<Team, String>
let memberNameFocus = lens(\Team.members) >>> [Item].ix(id: 2) >>> lens(\Item.name)

let team = Team(members: items)
memberNameFocus.preview(team)           // Optional("B")
memberNameFocus.set(team, "Updated")    // updates the member whose id == 2
```

**Zero-copy element mutation with `lift`**

`ix.lift` mutates the element at the focused index in place without CoW-copying the collection:

```swift
// Array: inout subscript — zero copies of the collection buffer
var team = Team(members: [Item(id: 1, name: "a"), Item(id: 2, name: "b")])
let itemReducer = EndoMut<Item> { $0.name = $0.name.uppercased() }
let teamReducer: EndoMut<Team> =
    lens(\Team.members)
        .compose([Item].ix(id: 2))
        .lift(itemReducer)

teamReducer(&team)   // only the one Item is mutated; the [Item] buffer is not copied
```

`ix` on `MutableCollection` passes `inout collection[index]` directly to the closure — Swift's subscript modify coroutine makes this genuinely zero-copy. `ix` on `Dictionary` copies the `Value` once (because the dictionary subscript returns `Value?`, not `inout Value`), but the dictionary buffer itself is not copied.

**Subscripts vs `ix` — two faces of the same concept**

For concrete collection types, `[Int].ix(2)` is equivalent to `affineTraversal(\[Int][safe: 2])`, and `[User].ix(id: 2)` mirrors `[User][id: 2]` for the replace-in-place case. Use the subscripts (`[safe:]`, `[id:]`) for direct element access; use `ix` when you need an optic you can compose. `ix(id:)` is limited to replace-in-place semantics — for the add-or-remove behaviour, use the `[id:]` subscript directly.

---

### IdentifiedArray — ordered collection with O(1) by-id access

The `[id:]` subscript above is O(n): every lookup re-scans the array. `IdentifiedArray<ID: Hashable & Sendable, Element: Sendable>` is a `Sendable`, value-type (copy-on-write) ordered collection that keeps a **user-defined order exactly like `Array`** while giving **O(1)** lookup and in-place update by a stable identifier. The order lives in the element buffer; a side index (a custom open-addressing hash table of `UInt32` offsets) maps id → position and never dictates order, so unsorted `UUID`s never reshuffle your data.

```swift
var users: IdentifiedArrayOf<User> = IdentifiedArray([
    User(id: 1, name: "Alice"),
    User(id: 2, name: "Bob"),
])

users[id: 1]?.name                         // "Alice"  — O(1)
users[id: 2] = User(id: 2, name: "Robert") // replace in place — O(1)
users.append(User(id: 3, name: "Carol"))   // tail — O(1) amortised
users.insert(User(id: 0, name: "Zed"), at: 0)
users.elements                             // ordered [Element]; users.ids → [0, 1, 2, 3]
```

Elements need not be `Identifiable` — supply the id via a closure or key path (matching the `[id:]` / `ix(id:by:)` overloads):

```swift
struct Project { let slug: String; var title: String }
let loaded = [Project(slug: "auth", title: "Auth")]
var projects = IdentifiedArray(loaded, id: \.slug)   // keyed by \.slug
projects[id: "auth"]?.title
```

Identifiers are unique: inserting an element whose id already exists replaces it in place (last-wins), keeping its position. The `[id:]` setter follows the same dispatch table as the collection subscript above, including the id-mismatch no-op guard.

**Complexity** (vs. a plain `[Element]` with `first(where:)`):

| Operation | `[Element]` | `IdentifiedArray` |
|---|---|---|
| lookup / update by id | O(n) | **O(1)** |
| append | O(1) | O(1) amortised |
| insert / remove at position | O(n) | O(n) (order preserved → tail reindex) |
| ordered iteration | O(n) | O(n) |

**First-class optics.** `IdentifiedArray` is an optical citizen — every optic composes with `>>>`:

```swift
IdentifiedArrayOf<User>.ix(id: 2)            // O(1) AffineTraversal, zero-copy in-place mutation
IdentifiedArrayOf<User>.ix(id: 2) >>> ^\User.name
IdentifiedArrayOf<User>.traversed            // Traversal over every element
IdentifiedArrayOf<User>.arrayIso             // lawful Iso  <-> [Element]
IdentifiedArrayOf<User>.dedupPrism           // Prism [Element] -> IdentifiedArray (succeeds iff ids unique)
IdentifiedArrayOf<User>.orderedDictionaryIso // lawful Iso <-> (ids, lookup) — the *honest* keyed iso
```

The `.dictionary` getter projects to `[ID: Element]` but is explicitly **lossy** (drops order) — a getter, not an iso. The lawful keyed iso is `orderedDictionaryIso`, which pairs the lookup with the order it would otherwise lose.

**Algebra and the lawful surface.** `IdentifiedArray` is a `Semigroup` — `<>` appends with last-wins on duplicate ids (associative). It deliberately has **no `Functor`/`Applicative`/`Monad`/`Monoid`**: a uniqueness-collapsing, key-carrying container can't satisfy those laws (an id-changing `map` would change the collection's count; `<*>`/`flatMap` would need duplicates the type forbids; `identity` has no `id` closure). For value transforms that change the element type, bridge through `.elements` (the lawful `Array` functor/monad) and rebuild with `dedupPrism` (surfaces collisions) or `arrayIso` (last-wins normalise) — at a copy cost. In-place, same-identity edits stay on the type via `subscript(id:)`, `ix(id:)`, and `traversed`.

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
let metersToFeet = iso(get: { $0 * 3.28084 }, reverseGet: { $0 / 3.28084 })  // Iso<Double, Double>

metersToFeet.over { $0 + 10 }(1.0)  // convert to feet, add 10, convert back
```

Every `Iso` is also a valid `Lens`, `Prism`, and `AffineTraversal` — use `.asLens`, `.asPrism`, or `.asAffineTraversal` to downcast when needed. The identity iso `Iso<A, A>.id` is the strongest neutral element — see [Identity Optic](#identity-optic-id).

**Iso as Monoid** — endomorphism isos (`Iso<A, A>`) form a `Monoid` under composition. Use `mconcat` to chain a sequence of lossless transforms into one:

```swift
func rotatePoint(_ p: Point) -> Point { Point(x: p.y, y: p.x) }
func rotatePointBack(_ p: Point) -> Point { Point(x: p.y, y: p.x) }
func scalePoint(_ p: Point) -> Point { Point(x: p.x * 2, y: p.y * 2) }
func scalePointBack(_ p: Point) -> Point { Point(x: p.x / 2, y: p.y / 2) }
func translatePoint(_ p: Point) -> Point { Point(x: p.x + 1, y: p.y + 1) }
func translatePointBack(_ p: Point) -> Point { Point(x: p.x - 1, y: p.y - 1) }

let rotate    = iso(get: rotatePoint,    reverseGet: rotatePointBack)
let scale     = iso(get: scalePoint,     reverseGet: scalePointBack)
let translate = iso(get: translatePoint, reverseGet: translatePointBack)

let point = Point(x: 1, y: 2)
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

```swift-sketch
@State var meters: Double = 1.0

// Editing in feet while storing in meters:
TextField("Feet", value: $meters[optic: metersToFeet], format: .number)
```

See [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) for the full bridge API.

---

### Newtype — Branded Values

`Newtype<Tag, RawValue>` is this library's equivalent of Haskell's `newtype` keyword: a zero-cost wrapper that gives a `RawValue` a distinct nominal identity via a phantom `Tag`. Two `Newtype`s with different tags are entirely different types to the compiler — even when the underlying `RawValue` is identical — so mixing them up is a compile-time error, not a runtime bug.

```swift
enum UserTag {}
enum OrderTag {}
typealias UserID  = Newtype<UserTag, Int>
typealias OrderID = Newtype<OrderTag, Int>

func fetch(_ id: UserID) { /* ... */ }
fetch(UserID(42))    // ✓ compiles
// fetch(OrderID(42))   // ✗ compile error — different type, even though both wrap Int
```

A common convention is to use the owning type itself as the tag, avoiding a separate empty enum:

```swift
struct Member { let id: Newtype<Member, Int> }
```

`Newtype` is also a `@propertyWrapper`, so a branded field still exposes its raw value through ordinary property access, with the wrapper itself reachable via `$`:

```swift
struct Visitor {
    @Newtype<UserTag, Int> var id: Int = 42
}

let visitor = Visitor()
visitor.id    // Int                   — the unwrapped raw value
visitor.$id   // Newtype<UserTag, Int> — the branded wrapper
```

`Newtype` inherits `Equatable`, `Hashable`, `Comparable`, `Codable`, `Sendable`, `Identifiable`, the full numeric stack, every `ExpressibleBy*Literal` protocol, and `Semigroup`/`Monoid` from `RawValue` through conditional conformances — so it behaves like its `RawValue` everywhere except at the type-checker boundary that keeps different tags from being confused.

**Bidirectional conversion.** Every `Newtype` ships a total, verified `Iso` back to its raw value:

```swift
UserID.iso.get(UserID(42))        // 42
UserID.iso.reverseGet(42)         // UserID(42)
```

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
let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
let lower   = Endo<String> { $0.lowercased() }
let exclaim = Endo<String> { $0 + "!" }

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

### Cost-Free Mutations (EndoMut)

`EndoMut<A>` is the in-place companion to `Endo<A>`. It wraps `(inout A) -> Void` instead of `(A) -> A`. The algebra is identical — `EndoMut` is still a `Monoid` under sequential application — but for Swift value types with Copy-on-Write (CoW) internals, the performance characteristics differ fundamentally.

#### Why `Endo<A>` is expensive on large Swift values

Swift's CoW types — `Array`, `Dictionary`, `Set`, `String` — store their contents in a heap buffer tracked by a reference count. Mutation is in-place only when the reference count of that buffer is exactly **1**. The moment it reaches 2, Swift copies the entire buffer before mutating.

When you call a pure `(A) -> A` function:

```swift-sketch
let newState = reducer(action)(state)
//                             ^^^^^
// At this point `state` in the caller still holds a reference to every
// CoW buffer. The function argument holds a second reference.
// Reference count = 2  →  any mutation inside copies the whole buffer.
```

This means that for every reducer call on a state containing a 100 000-element array, touching even a single element triggers an O(n) heap copy — even if nothing else in the state changes.

#### Why `EndoMut` avoids those copies

`EndoMut` passes the value by exclusive reference:

```swift-sketch
reducer(action)(&state)
//              ^^^^^^
// Swift's Law of Exclusivity (SE-0176) statically guarantees no other
// code holds an alias to `state` for the duration of this call.
// Reference count = 1  →  CoW mutates the buffer in place.
```

The exclusivity guarantee is enforced by the compiler, not convention. You cannot hold another reference to the same value while an `inout` borrow is active — the compiler rejects the code at compile time. This makes `EndoMut` semantically pure: there is no shared mutable state, and the transformation is referentially transparent at the call site.

#### Usage

```swift
var items = Array(0..<10_000)

let clamp = EndoMut<[Int]> { xs in for i in xs.indices { xs[i] = min(xs[i], 100) } }
let sort  = EndoMut<[Int]> { $0.sort() }

let normalise: EndoMut<[Int]> = mconcat([clamp, sort])
normalise.runEndoMut(&items)   // clamps first, then sorts — no copies
normalise(&items)              // callAsFunction also works
```

`EndoMut.combine(f, g)` applies `f` first, then `g` — `g` sees every mutation `f` made. The `<>` operator and `mconcat` follow from the `Semigroup`/`Monoid` conformances:

```swift
let clamp = EndoMut<[Int]> { xs in for i in xs.indices { xs[i] = min(xs[i], 100) } }
let sort  = EndoMut<[Int]> { $0.sort() }
var items = Array(0..<10_000)

(clamp <> sort)(&items)                    // same as mconcat([clamp, sort])
```

#### Bridging between `Endo` and `EndoMut`

The two types are isomorphic as monoids. Converting `Endo → EndoMut` is free (no extra copy). Converting `EndoMut → Endo` always makes one copy — that copy is precisely what pure-function semantics require.

```swift
// Endo → EndoMut (free — no extra copy)
let mutating: EndoMut<Int> = Endo<Int> { $0 + 1 }.toEndoMut()

// EndoMut → Endo (one copy of the value)
let pure: Endo<Int> = EndoMut<Int> { $0 += 1 }.toEndo()

// Round-trips preserve semantics
let original = EndoMut<Int> { $0 *= 2 }
let roundTripped = original.toEndo().toEndoMut()
// original and roundTripped produce the same result for any input
```

**`Endo` vs `EndoMut`**

| | `Endo<A>` | `EndoMut<A>` |
|---|---|---|
| Function type | `(A) -> A` | `(inout A) -> Void` |
| CoW containers | copied on mutation | mutated in place |
| Composable | yes — `Monoid` | yes — same `Monoid` |
| Bridgeable | `.toEndoMut()` (free) | `.toEndo()` (one copy) |
| Use when | values are small / opaque | `Array`, `Dictionary`, large structs |

#### Lifting `EndoMut` through optics

Every optic (`Lens`, `Prism`, `AffineTraversal`) has a `lift` method that zooms an `EndoMut<A>` out to an `EndoMut<S>` through the optic's focus. This is the idiomatic way to write reducers over large states without triggering CoW copies.

```swift
// A reducer over a sub-state
let itemReducer = EndoMut<Item> { item in item.views += 1 }
let selectedId = 2
var appState = AppState(feed: [Item(id: 2, name: "b")])

// Lift it to the full AppState using a composed optic chain
let appReducer: EndoMut<AppState> =
    lens(\AppState.feed)
        .compose([Item].ix(id: selectedId))
        .lift(itemReducer)

appReducer(&appState)
// ✓ AppState is not copied
// ✓ [Item] buffer is not copied (direct inout subscript)
// ✓ Only the one Item is mutated in place
```

**Copy cost at each link**

The cost of a composed chain is the sum of its links:

| Optic | `lift` copy cost |
|---|---|
| `lens(\.varProp)` — `WritableKeyPath` | zero-copy (Swift modify coroutine) |
| `lens(\.letProp) { … }` — computed setter | copies focused value `A` once |
| `ix` on `MutableCollection` | zero-copy (direct inout subscript) |
| `ix` on `Dictionary` | copies `Value` once; dictionary buffer not copied |
| `Prism` (enum case) | copies associated value once; outer `S` not copied |
| Composition chain | propagates per link — outer `S` is always `inout` |

The outer `S` is **always** kept as `inout` throughout the chain — only the focused sub-value at each link is ever extracted and written back.

**`compose` without operators**

If you import only `CoreFP` (no `CoreFPOperators`), use `compose` in place of `>>>`:

```swift
let itemReducer = EndoMut<Item> { item in item.views += 1 }
let selectedId = 2

let appReducer: EndoMut<AppState> =
    lens(\AppState.feed)
        .compose([Item].ix(id: selectedId))
        .lift(itemReducer)
// identical to the >>> form above
```

**`Stateful<S, Void>` ↔ `EndoMut<S>`**

`Stateful<S, Void>` and `EndoMut<S>` wrap the same closure type `(inout S) -> Void`. Convert freely between them at zero cost:

```swift
let endoMut = EndoMut<AppState> { $0.counter += 1 }
let stateful: Stateful<AppState, Void> = endoMut.toStateful()  // free
let backToEndo: EndoMut<AppState> = stateful.toEndoMut()       // free
```

**Zooming `Stateful` computations through optics**

When a computation needs to *return a value* in addition to mutating state, use `zoom` instead of `lift`. `zoom` lifts a `Stateful<A, Result>` to a `Stateful<S, Result>` through the optic's focus. For `Prism` and `AffineTraversal`, the result is `Result?` — `nil` when the focus is absent:

```swift
let pop = Stateful<[Item], Item?> { items in
    guard !items.isEmpty else { return nil }
    return items.removeLast()
}

// Zoom into the feed array inside AppState
let appState = AppState(feed: [Item(id: 1, name: "a")])
let appPop: Stateful<AppState, Item?> = lens(\AppState.feed).zoom(pop)
let (removedItem, newState) = appPop.runStateful(appState)
```

The outer `S` is always `inout`; only the focused `Part` is extracted and written back.

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
Result<Int, String>.failure("oops").isB   // true (failure maps to the right/B case)

// from — convert between any two conforming types with the same type parameters
let r = Result<Int, String>.from(Either<Int, String>.left(42))  // .success(42)
```

The protocol has three requirements, `left(_:)`, `right(_:)` and `match(caseLeft:caseRight:)`; `from(_:)`, `.a`, `.b`, `.isA` and `.isB` come for free as extensions. Use `SumType2` in your own generic functions to work over `Either`, `Result`, and any custom two-case type simultaneously.

Note that the mapping is positional: `Result`'s `A` is `Success`, while `Either`'s success-by-convention side is `.right` (`B`), so `Result.from(Either.right(x))` is `.failure(x)`.

---

### Concurrency: Sendable-First

FP is a **Sendable-first** library. Composition (functor / applicative / monad / transformer operators, function helpers, optics, etc.) requires `@Sendable` closures end-to-end; side effects live at the boundary, outside the composition layer.

This is a deliberate FP discipline rather than a Swift concurrency quirk: composition should be pure, and `@Sendable` is the strongest static guarantee Swift gives us that a closure carries no side-channel state.

#### Closures should ideally capture *nothing*

`@Sendable` rules out closures that capture non-Sendable values (mutable view-controller state, services, classes), and that's the first line of defence. But the deeper FP principle is stronger: **the closures you pass to `map` / `flatMap` / `<*>` / `compose` / `>=>` ideally shouldn't capture anything at all** — not even Sendable values.

A closure that captures a captured variable introduces hidden inputs (or hidden outputs). Two flavours:

- **Effect** — the closure writes to something outside itself: increments a counter, mutates a class property, logs, sends a network request. The function's *output* depends on more than its arguments; it changes the world.
- **Co-effect** — the closure reads from something outside itself: a global, a singleton, the current time, a flag stored in `self`. The function's output depends on more than its arguments; it observes the world.

Either kind of capture breaks **referential transparency** — the property that `f(x)` always returns the same value for the same `x`, and that replacing `f(x)` with its result anywhere in the program doesn't change behaviour. Without referential transparency, equational reasoning collapses: you can no longer refactor by substitution, test by passing arguments, or rely on the functor/applicative/monad laws.

The library can't enforce capture-freeness at the type level — Swift has no `@Pure` attribute — so it does the next-best thing and requires `@Sendable`, which at least blocks non-Sendable captures. The intent is for you to go further:

```swift-sketch
// ❌ Co-effect: reads `formatter` from the enclosing scope
let formatter = DateFormatter()  // (Sendable struct, would compile)
let render = { (date: Date) -> String in formatter.string(from: date) }

// ❌ Effect: writes `count` from the enclosing scope
var count = 0
let increment = { (n: Int) -> Int in count += 1; return n + count }

// ✅ Capture-free: depends only on its argument
let render = { (date: Date) -> String in
    DateFormatter().string(from: date)   // or pass the formatter as an argument
}

// ✅ State threaded explicitly through the type system
let increment: @Sendable (Int) -> Stateful<Int, Int> = { n in
    Stateful<Int, Int> { state in state += 1; return n + state }
}
```

Where state, dependencies, environments, or accumulated logs are unavoidable, the library gives you a *type* to represent them: `Stateful` for mutation, `Reader` for dependencies, `Writer` for accumulated logs, `Either` / `Validation` for failure. Lift the would-be capture into one of those, and the closure stays capture-free while the dependency becomes visible in the function's type signature.

Closures that capture nothing can't surprise you. That's the bar; `@Sendable` is the floor.

#### What's `Sendable` in the library

| Layer | Sendable status |
|---|---|
| All algebraic types (`Either`, `Validation`, `Reader`, `Stateful`, `Writer`, `Loading`, `Newtype`, `Endo`, `EndoMut`, `Iso`, `Lens`, `Prism`, `AffineTraversal`, transformer stacks such as `ReaderTArray`, …) | **Conditionally** `Sendable` when their type parameters are Sendable |
| `NonEmpty`, `IdentifiedArray` | Always `Sendable`; their element (and id) types are *required* to be `Sendable` |
| `Semigroup`, `Monoid`, `SumType2`, `FunctionWrapper`, `CaseMatchable`, `HasCases`, `HasMax`, `HasMin`, `SIMDMonoidScalar` | Refine `Sendable` (conformers must be Sendable) |
| `apply` / `<*>` / `flatMap` / `>>-` / `>=>` / `liftA2` / `fmap` / `<£>` / `>>>` / composition helpers (`compose`, `curry`, `flip`, `withArg`, …) | Take and return `@Sendable` closures |
| `KeyPath` / `WritableKeyPath` | Retroactively `@unchecked Sendable` (immutable metadata, safe to share) |

#### Lifting `KeyPath` into `@Sendable` functions

Swift's implicit `KeyPath → (Root) -> Value` conversion produces a closure that is **not** `@Sendable`, even though `KeyPath` itself is Sendable. To pass a key path into composition, lift it explicitly:

```swift
import CoreFP            // `get(_:)` — unambiguous free function
import CoreFPOperators   // prefix `^` — terse form

let predicate1 = compose(get(\User.name), equals("Alice"))      // 1. Unambiguous
let predicate2 = compose(^\User.name, equals("Alice"))          // 2. Operator
let predicate3 = compose({ (user: User) in user.name }, equals("Alice"))   // 3. Explicit closure
```

The `^` prefix operator is overloaded:
- `^\Person.age` on a `WritableKeyPath` returns a `Lens<Person, Int>`.
- `^\Person.name` on a `KeyPath` (`let` property) returns either a curried Lens builder or a `@Sendable (Person) -> String` getter, picked by call-site context. When the context is ambiguous, fall back to `get(_:)`.

#### Side effects at the boundary

A `@Sendable` closure can capture `self` only if `self` is itself Sendable. View controllers, view models, and most reference types aren't — and shouldn't be smuggled into composition. The library uses two boundary patterns:

```swift-sketch
// 1. Combine — `sink` is non-@Sendable, accepts non-Sendable self
publisher
    .map(parseUser)             // pure composition, @Sendable closures
    .sink { [weak self] user in self?.update(user) }   // boundary

// 2. Reader — pass dependencies through the environment, not via capture
reader.runReader(env)            // returns a value; act on `self` next to it
```

#### Composition surfaces forbid `inout` captures

`Stateful<S, A>` stores `@Sendable (inout S) -> A` and threads state through `flatMap`. The `@Sendable` requirement forbids capturing an `inout` from an enclosing scope into the closure body, so applicative / monad combinators evaluate each sub-`Stateful` *before* wrapping the next `@Sendable` block:

```swift-sketch
Stateful<S, B> { s in
    let f = sf.run(&s)           // run sf first  (state advances)
    let a = sa.run(&s)           // run sa second (state advances again)
    return ...                   // combine results inside the @Sendable body
}
```

This matches the standard left-to-right applicative semantics for State.

#### Algebra protocols imply `Sendable`

Because the algebra layer is intended for value types you compose and pass around, `Semigroup` (and therefore `Monoid`, `SumType2`, etc.) refine `Sendable`. The standard numeric, string, array, set, dictionary, and option types satisfy this trivially. If you write a custom `Semigroup`, the conforming type must be `Sendable` — usually free for value types.

---

### Utilities

**Function composition** — `>>>` and `<<<`

`>>>` chains functions left-to-right; `<<<` chains right-to-left. Both produce a single function from the chain:

```swift
func trim(_ s: String) -> String { s.trimmingCharacters(in: .whitespaces) }
func uppercased(_ s: String) -> String { s.uppercased() }
func exclaim(_ s: String) -> String { s + "!" }

let shout  = trim >>> uppercased >>> exclaim   // left-to-right
let shout2 = exclaim <<< uppercased <<< trim   // right-to-left — equivalent

shout("  hello  ")    // "HELLO!"
shout2("  hello  ")   // "HELLO!"
```

Key paths lifted with `get(_:)` (or prefix `^`) are `@Sendable` functions, so they compose too, which is useful when building point-free transformations over nested types:

```swift
struct Company { var ceo: Person }

let ceoName: @Sendable (Company) -> String = get(\Company.ceo) >>> get(\Person.name)
let companies = [Company(ceo: Person(name: "Ada", age: 36))]
companies.map(ceoName)   // ["Ada"]
```

---

**Function application** — `<|` and `|>`

`<|` applies a function to a value with the function on the left (Haskell's `$`). Its precedence group is lower than every other operator, so it eliminates wrapping parentheses. It is right-associative, so chains nest naturally:

```swift
uppercased <| trim <| "  hello  "   // "HELLO" — evaluated right-to-left: trim first, then uppercased
```

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
func process(_ transform: (String) -> String = id) -> String { transform("x") }

// Use in Optional.fold to pass values through the some branch unchanged:
Optional("x").fold(onNone: "", onSome: id)
```

---

**`const`** — ignore arguments, return a fixed value

`const` produces a function that ignores all its arguments and returns a single value. Overloads cover zero to three ignored arguments individually; four or more use a variadic tail:

```swift
// Single-argument: replaces { _ in 42 }
[1, 2, 3].map(const(42))                     // [42, 42, 42]
Optional("hello").map(const(true))            // Optional(true)

// Multi-argument: replaces { _, _ in "fixed" } or { _, _, _, _ in "fixed" }
let alwaysZero: (Int, String, Bool) -> Int = const(0)
alwaysZero(99, "ignored", true)              // 0

// Combine with map to replace contents:
[1, 2].map(const(Result<Void, MyError>.success(())))   // all successes, structure preserved
```

---

**`flip`, `curry`, `uncurry`, `partialApply`**

```swift
// flip — swap the two arguments of a binary function
flip(-)(3)(10)           // 7    — equivalent to 10 - 3
[1, 2, 3].reduce(0, flipU(+))  // sum, argument order doesn't matter for +

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
let describe: @Sendable (String) -> (Int, Character?, String) = fanout(\.count, \.first, uppercased)
let (count, first, upper) = describe("hello")
// (5, Optional("h"), "HELLO")

// Useful for building a summary from a single pass:
let summarize: @Sendable (Employee) -> (String, Int, Bool) = fanout(\.name, \.age, \.isAdmin)
[Employee(name: "Alice", age: 30, isAdmin: true)].map(summarize)
// [(String, Int, Bool)]
```

---

**`join` and `void`**

`join` flattens one layer of nesting; `void` discards the contained values while keeping the container shape:

```swift
// join — one layer in, same container out
join([[1, 2], [3, 4]])                                    // [1, 2, 3, 4]
join(Optional(Optional(42)))                              // Optional(42)
join(Result<Result<Int, MyError>, MyError>.success(.success(42)))     // .success(42)

// void — like map(ignore); keeps structure, discards values
void([1, 2, 3])          // [(), (), ()]
void(Optional(42))       // Optional(())
void(Result<Int, MyError>.success(99))   // .success(())
```

`void` differs from `ignore`: `ignore` is `(A) -> Void` (discards a single value entirely), while `void` is `Container<A> -> Container<Void>` (maps every element to `()`). Use `ignore` when you want to drop a value; use `void` when you want to strip the values from a container but keep its structure.

---

**Tuple utilities**

```swift
mapTuple2(uppercased)("hello", "world")    // ("HELLO", "WORLD")
mapTuple3({ $0 * 2 })(1, 2, 3)           // (2, 4, 6)
tuple(1, "hello")                          // (1, "hello")
untuple { (pair: (Int, Int)) in pair.0 + pair.1 }(3, 4)   // 7 (one tuple argument becomes two separate arguments)
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
let items: [Any] = [URL(string: "https://ios.lu") as Any, 42, "text"]
items.compactMap(castOptionally(URL.self))   // [URL] — only URLs survive
```

---

**`lazy` / `unlazy`** — defer and force evaluation

```swift
func expensiveComputation() -> Int { 42 }
let later: @Sendable () -> Int = lazy(expensiveComputation())   // not evaluated yet
unlazy(later)                                          // forces it
```

---

**Conversions**: `to…()` and `init(_:)`

Related types convert with `to…()` going out and `init(_:)` coming in, so there is no guessing which direction a bridge goes:

```swift
let e: Either<String, Int> = .right(1)

e.toResult()                 // Result<Int, String>.success(1)  (the left side must be an `Error`)
e.toValidation()             // Validation<String, Int>.success(1)
Validation(e).toEither()     // Either<String, Int>.right(1)
Loading<Int, String>(Result<Int, String>.success(1))   // .loaded(1)
```

`These(either)` and `Zipper(nonEmpty)` follow the same convention.

---

**Boolean predicates** — curried, composable, for fully tacit style

`equals`, `notEquals`, `not`, `and`, `or` are overloaded for both `Bool` values and `(A) -> Bool` predicates, so they compose directly with key paths, `<<<`/`>>>`, and `flip` to build predicates without any closure syntax:

```swift
struct Employee { let name: String; let age: Int; let isAdmin: Bool }
let users = [Employee(name: "Alice", age: 30, isAdmin: true), Employee(name: "Bob", age: 17, isAdmin: false)]

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
struct Endpoint: Mutable { var host: String; var port: Int }

let base = Endpoint(host: "localhost", port: 8080)
let dev  = base.mutate { $0.port = 3000 }     // Endpoint(host: "localhost", port: 3000)
let prod = base.mutate { $0.host = "prod.example.com" }
```

---

**`clamped(to:)` / `within(_:)`** — `Comparable` range helpers

`clamped(to:)` constrains a value to a closed range, returning the nearest endpoint when it falls outside. `within(_:)` is a value-first phrasing of `range.contains(value)`:

```swift
5.clamped(to: 0...10)       // 5
(-3).clamped(to: 0...10)    // 0
42.clamped(to: 0...10)      // 10
3.5.clamped(to: 0.0...1.0)  // 1.0

42.within(40...50)          // true
42.within(40...42)          // true
42.within(30...41)          // false

// Combines with `±` (requires `Strideable`, see operator reference):
41.within(42 ± 2)           // true — 41 falls inside 40...44
```

---

**`Array.cartesian`** — n-ary Cartesian product

`cartesian` pairs every element of the input arrays into typed tuples. Unlike `zip`, which stops at the shortest array and only matches positions, `cartesian` produces every `n × m × …` combination:

```swift
Array.cartesian([1, 3, 5], ["a", "b"])
// [(1, "a"), (1, "b"), (3, "a"), (3, "b"), (5, "a"), (5, "b")]

Array.cartesian([1, 2], ["a"], [true, false])
// [(1, "a", true), (1, "a", false), (2, "a", true), (2, "a", false)]

// Any empty input collapses the result to []:
Array.cartesian([], [1], [1])    // []
```

Overloads exist for 2-, 3-, and 4-arity inputs. Functionally equivalent to applying `liftA2`-style tuple construction over the list applicative, but the dedicated overload preserves the tuple shape without going through a closure.

---

**`ignore` / `absurd`** — structural helpers

```swift
// ignore — discard a value and return ()
[1, 2, 3].map(ignore)         // [(), (), ()]
[1, 2, 3].forEach(ignore)     // explicitly discard values

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
| `<£>` | `<&>` | Functor map — fn left / container left | `Optional`, `Array`, `Result`, `Publisher`, `AsyncSequence`, functions, `Either`, `Validation`, `Loading`, `Reader`, `Stateful`, `Writer`, `NonEmpty`, `These`, `Zipper`, every transformer stack |
| `£>` | `<£` | Replace contents with a constant — container left / value left | same as `<£>` |
| `<*>` | — | Applicative apply — wrapped function on left, wrapped value on right | same as `<£>`, minus `Zipper` |
| `*>` | `<*` | Sequence two effects — keep right / keep left | same as `<*>` |
| `>>-` | `-<<` | Monadic bind — container left / fn left | `Optional`, `Array`, `Result`, `Publisher`, `AsyncSequence`, functions, `Either`, `Loading`, `Reader`, `Stateful`, `Writer`, `NonEmpty`, `These`, and the `MonadT` stacks (not `Validation`, not `TransformerStack`-only stacks) |
| `->>` | `<<-` | Comonad extend — container left / fn left | `Writer`, `NonEmpty`, `Zipper`, `Reader` (when `Environment: Monoid`) |
| `>=>` | `<=<` | Kleisli composition — left-to-right / right-to-left | same as `>>-` |
| `>>>` | `<<<` | Function / optics composition — left-to-right / right-to-left | Functions, `Iso`, `Lens`, `Prism`, `AffineTraversal`, `Traversal` |
| `<\|` | `\|>` | Function application — fn left / value left | Any function |
| `<\|>` | — | Alternative / choice | `Optional`, `Array`, `Result`, `Either`, `Publisher`, `Validation` (accumulates both failures with `<>`) |
| `<>` | — | Semigroup append | `String`, `Array`, `Optional`, `Dictionary`, `Set`, `Endo`, `EndoMut`, `Iso<A, A>`, `Reader`, `Writer`, `NonEmpty`, `Newtype`, `IdentifiedArray`, `Result.Monoids.*`, `Int.Monoids.*`, `Bool.Monoids.*`, `SIMDn<T>.Monoids.*`, Min/Max/First/Last/Dual, … |
| `^` _(prefix)_ | — | Lift `WritableKeyPath` → `Lens`; `KeyPath` → partial `Lens` builder or `@Sendable (Root) -> Value` getter, chosen by context | `WritableKeyPath`, `KeyPath` |
| `±` / `+/-` | — | Symmetric range — `center ± delta` → `ClosedRange` | `Strideable` (`Int`, `Double`, `Float`, `Date`, …) |
| `≅` | — | Flipped range match — `value ≅ range` (equivalent to `range ~= value`) | `Comparable` |

Transformer stacks (`ReaderTArray`, …): `<£>`, `<&>`, `£>`, `<£`, `<*>`, `*>`, `<*` on all of them; `>>-`, `-<<`, `>=>`, `<=<` only on the stacks that conform to `MonadT`.

#### Operator Precedence

Every custom operator lives in one of the precedence groups defined in `Sources/CoreFPOperators/Utilities/PrecedenceGroups.swift`, interleaved with Swift's standard-library groups so custom and built-in operators combine predictably. From highest to lowest:

| Level | Operators | Associativity | Precedence group |
|---|---|---|---|
| 9.1 | `>>>` | right | `FunctionCompositionForward` |
| 9 | `<<<` | right | `FunctionCompositionBackwards` |
| 8.5 | `>>` _(stdlib)_ | left | `BitwiseShiftPrecedence` |
| 7 | `*`, `/` _(stdlib)_ | left | `MultiplicationPrecedence` |
| 6.5 | `<>` | right | `ConcatPrecedence` (strictly between multiplication and addition) |
| 6 | `+`, `-` _(stdlib)_ | left | `AdditionPrecedence` |
| 4.8 | `...`, `..<` _(stdlib)_, `±` / `+/-` | none | `RangeFormationPrecedence` |
| 4.5 | `as?` _(stdlib)_ | none | `CastingPrecedence` |
| 4.2 | `??` _(stdlib)_ | right | `NilCoalescingPrecedence` |
| 4 | `==`, `<=` _(stdlib)_, `≅` | none | `ComparisonPrecedence` |
| below `??`, above `<\|>` | `<£>`, `£>`, `<£`, `<*>`, `*>`, `<*` | left | `FunctorOps` (no declared relation to the comparison operators: parenthesise when mixing with `==`) |
| 3 | `<\|>` | left | `AlternativePrecedence` |
| 3 | `&&` _(stdlib)_ | left | `LogicalConjunctionPrecedence` |
| 2 | `\|\|` _(stdlib)_ | left | `LogicalDisjunctionPrecedence` |
| 1.1 | `>=>`, `<=<`, `-<<`, `<<-` | right | `KleisliCompositionRight` |
| 1 | `>>-`, `<&>`, `->>` | left | `MonadBindLeft` |
| 0.5 | `?:` _(stdlib)_ | right | `TernaryPrecedence` |
| 0 | `<\|` | right | `LowPrecedenceFunctionCallRight` |
| 0 | `\|>` | left | `LowPrecedenceFunctionCallLeft` |
| -1 | `=` _(stdlib)_ | right | `AssignmentPrecedence` |

Practical takeaways:
- `>>>` / `<<<` bind tighter than everything else, so composed functions and optics never need parentheses next to arithmetic or comparisons.
- `<|` / `|>` sit near the very bottom (just above assignment), which is what lets them wrap an entire expression without parentheses — `f <| a + b * c` parses as `f <| (a + b * c)`.
- `>=>` / `<=<` / `-<<` / `<<-` (`KleisliCompositionRight`, right-associative) bind slightly tighter than `>>-` / `<&>` / `->>` (`MonadBindLeft`, left-associative). Haskell puts both at level 1 (`infixr 1` / `infixl 1`), where mixing them without parentheses is an error; Swift needs two ordered groups, so `x >>- f >=> g` means `x >>- (f >=> g)`.

---

### Types

Each type in this library has a dedicated reference page with comprehensive examples covering every operation, operator, and transformer combination.

Links below point at the DocC article source in this repository — each type's article lives in the `.docc` catalog of the module that actually declares it (`CoreFP` or `DataStructure`) — which is the same content rendered at the hosted documentation site, [ios.lu/FP](https://ios.lu/FP).

#### CoreFP

| Type | Description |
|------|-------------|
| [Optional](Sources/CoreFP/CoreFP.docc/Optional.md) | Swift's built-in optional, extended with full Functor / Applicative / Monad instances |
| [Array](Sources/CoreFP/CoreFP.docc/Array.md) | Swift's built-in array, extended — models nondeterminism and multiple results |
| [Result](Sources/CoreFP/CoreFP.docc/Result.md) | Swift's built-in result, extended with `bimap`, Kleisli composition, and Monoid strategies |
| [Publisher](Sources/CoreFP/CoreFP.docc/Publisher.md) | Combine's `AnyPublisher`, extended with functional operations |
| [AsyncSequence](Sources/CoreFP/CoreFP.docc/AsyncSequence.md) | Swift's `AsyncSequence`, extended with functional operations |
| [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) | SwiftUI's `Binding`, extended with `[optic:]` subscripts for `Lens`, `Iso`, `Prism`, and `AffineTraversal` _(Apple platforms only)_ |

#### DataStructure

| Type | Description |
|------|-------------|
| [Either](Sources/DataStructure/DataStructure.docc/Either.md) | Unconstrained sum type — both sides are equal citizens, no `Error` requirement |
| [Loading](Sources/DataStructure/DataStructure.docc/Loading.md) | Four-state async lifecycle — `idle` / `loading` / `loaded` / `failed`; `loadedOrPrevious` keeps a view showing the last good value through a refresh or an error instead of blanking out. `Failure` can be any `Sendable` type (a `String`, a view struct), not only `Error`; `<*>` / `zip` are the lawful left-biased applicative, and the old "failed beats idle beats loading" combination is `pessimisticCombine` |
| [Validation](Sources/DataStructure/DataStructure.docc/Validation.md) | Accumulating applicative — errors collect instead of short-circuiting. `<\|>` accumulates both failures with `<>`; convert with `Validation(either)` / `validation.toEither()` |
| [Reader](Sources/DataStructure/DataStructure.docc/Reader.md) | Dependency injection monad — wraps `(Environment) -> Output` |
| [Stateful](Sources/DataStructure/DataStructure.docc/Stateful.md) | State threading monad — wraps `(inout S) -> A` |
| [Writer](Sources/DataStructure/DataStructure.docc/Writer.md) | Append-as-you-go monad — produces a value alongside an accumulated log |
| [NonEmpty](Sources/DataStructure/DataStructure.docc/NonEmpty.md) | Statically guaranteed non-empty sequence — Semigroup (no Monoid), full FAM + Foldable + Traversable; requires `Sendable` elements |
| [IdentifiedArray](Sources/DataStructure/DataStructure.docc/IdentifiedArray.md) | Ordered, `Sendable` collection with O(1) by-id access via a custom open-addressing index — Semigroup, first-class optics (no Functor/Monad by design) |
| [These](Sources/DataStructure/DataStructure.docc/These.md) | Inclusive-or: this, that, or both — Applicative/Monad when the left side is a Semigroup |
| [Zipper](Sources/DataStructure/DataStructure.docc/Zipper.md) | Focused list with O(1) moves — a lawful Comonad |
| [Gen](Sources/DataStructure/DataStructure.docc/Gen.md) | Property-based random generator over an injected RNG (`Stateful<R, Value>`) |

---

### Generating Code with Macros (`@Lenses`, `@Prisms`, `@ApplyOptics`, `@Iso`, `@DeriveMonoid`, `@Mock`, `@Witness`)

Import `FPMacros` to generate boilerplate directly from type and protocol declarations: `@Lenses` and `@Prisms` derive optics from structs and enums, and `@ApplyOptics` derives them recursively over a whole nested tree; `@Iso` derives a lossless struct ↔ tuple conversion; `@DeriveMonoid` derives a fieldwise `Monoid`; `@Mock` and `@Witness` derive protocol testing/DI scaffolding. All seven attach members (and, for some, an extension), so they work on types nested inside other types, but not on types local to a function body (Swift forbids extension macros there).

```swift
import FPMacros
```

#### `@Lenses` — struct lenses

`@Lenses(_:init:)` generates a memberwise initializer, a `Lenses` struct + `static var lens` accessor holding one `Lens` per stored property, a `with(...)` copy-with-overrides helper, and `Sendable` conformance when the struct doesn't declare it (`CoreFP.lens` needs a `Sendable` host, and a `public` struct never gets one implicitly).

**Property rules:**

| Property | In generated `init`? | Gets a `Lens`? | Lens kind |
|---|---|---|---|
| `let name: T` | yes — required | yes | reconstruction (calls `init` via the generated `with(...)`) |
| `let version = 1` | no | no | immutable constant |
| `var port: Int` | yes — required | yes | `WritableKeyPath` |
| `var timeout = 30` | yes — default `= 30` | yes | `WritableKeyPath` |
| `var count: Int { didSet { … } }` | yes — required | yes | `WritableKeyPath` (observers keep it stored) |
| `var a, b: Int` | yes — both | yes — both | `WritableKeyPath` |
| `var name: String!` | yes — default `= nil` | yes, typed `String?` | `WritableKeyPath` |
| `public private(set) var total: Int` | yes — required | yes, capped to `fileprivate` | `WritableKeyPath`; left out of the public `with(...)` |

```swift
@Lenses(init: .public)
public struct AppConfig {
    public let host: String
    public let version = 3       // constant — no lens, excluded from init
    public var port: Int
    public var timeout = 30
}
```

**Expanded code (simplified):**

```swift-sketch
public struct AppConfig {
    public let host: String
    public let version = 3
    public var port: Int
    public var timeout = 30

    public init(host: String, port: Int, timeout: Int = 30) {
        self.host = host; self.port = port; self.timeout = timeout
    }

    public struct Lenses: Sendable {
        public let host:    Lens<AppConfig, String> = CoreFP.lens(\AppConfig.host) { s, a in s.with(host: a) }
        public let port:    Lens<AppConfig, Int>    = CoreFP.lens(\AppConfig.port)
        public let timeout: Lens<AppConfig, Int>    = CoreFP.lens(\AppConfig.timeout)
    }
    public static var lens: Lenses { Lenses() }

    public func with(host: String? = nil, port: Int? = nil, timeout: Int? = nil) -> AppConfig {
        AppConfig(
            host: host ?? self.host,
            port: port ?? self.port,
            timeout: timeout ?? self.timeout
        )
    }
}
extension AppConfig: Sendable {}
```

The `Lens<AppConfig, String>` for `host` (a `let` property) calls `s.with(host: a)` rather than inlining all field references — the `with(...)` helper is the single source of truth for reconstruction, keeping the codegen O(N) in the number of properties instead of O(N²).

`lens` is always computed: Swift forbids `static let` in any generic context, which includes generic hosts (`Container<T>`) and structs nested in a generic type (which the macro can't see). Building `Lenses()` is cheap. A generic host gets `extension Container: Sendable where T: Sendable {}` for the generic parameters its stored properties use.

**Usage:**

```swift
let config = AppConfig(host: "localhost", port: 8080)

AppConfig.lens.host.set(config, "example.com")
// AppConfig(host: "example.com", port: 8080, timeout: 30, version: 3)

AppConfig.lens.port.over({ $0 + 1 })(config)
// AppConfig(host: "localhost", port: 8081, timeout: 30, version: 3)

config.with(host: "example.com", port: 9090)
// same effect, without needing lenses

// Lenses compose as normal:
//   lens(\Team.config) >>> AppConfig.lens.host
```

**Optional properties and `with(...)`**

For properties whose type is `T?`, `with(...)` uses a double-Optional parameter under the hood so the common ergonomic call sites all behave intuitively:

```swift
@Lenses(init: .public)
public struct Server {
    public let port: Int?
    public let name: String
}

let s = Server(port: 8080, name: "main")
s.with()                // Server(port: 8080,  name: "main")   — keep
s.with(port: nil)       // Server(port: nil,   name: "main")   — clear
s.with(port: 9090)      // Server(port: 9090,  name: "main")   — set
s.with(name: "primary") // Server(port: 8080,  name: "primary") — non-Optional still works
```

The trick: the parameter type is `Int?? = .some(nil)`. The default `.some(nil)` means "no change"; a bare `nil` literal at the call site binds to outer-`.none`, meaning "clear"; any value `v` wraps to `.some(.some(v))`, meaning "set". Non-Optional properties use the simpler `T? = nil` + `??` form.

**Slicing the output**

Use `LensesEmit` to opt out of pieces you don't need:

```swift
@Lenses(.all) struct Full { var x = 0 }                 // default: init + lens + with
@Lenses(.initOnly) struct InitOnly { var x = 0 }        // only the memberwise init
@Lenses(.lensesOnly) struct LensesOnly {                // lens + with, no init at all
    var x: Int
    init(x: Int) { self.x = x }                         // (use when you have a custom init)
}
```

If the struct already declares an `init` whose parameter labels match what the macro would generate, the macro skips its own init silently — the user's init wins.

**Visibility skip**

Properties whose declared visibility is *lower* than the struct's are excluded from both the lens namespace and `with(...)`, with a diagnostic note. The init still includes them (it can legally assign lower-visibility properties from inside the struct).

#### `@Prisms` — enum prisms

`@Prisms` generates three things for the annotated enum:

1. A `Prisms` struct + `static var prism` accessor holding a typed `Prism` for each case, plus `Prismatic` conformance (unlocks composable `\.case` key paths).
2. One plain per-case property per case (`shape.circle`, `shape.rectangle`, …), typed `AssociatedValue?` — `nil` unless `self` is that case. Each delegates to the `Prism` from (1), so there's no duplicated pattern-matching logic.
3. A nested `enum Cases: CaseMatchable` (which inherits `CaseIterable`) whose cases mirror the case *names* of the original enum (no associated values), plus a `func is(_:) -> Bool` predicate.

```swift
@Prisms
public enum Figure {
    case circle(Double)
    case rectangle(Double, Double)
    case empty
}
```

**Expanded code (simplified):**

```swift-sketch
public enum Figure {
    case circle(Double)
    case rectangle(Double, Double)
    case empty

    public struct Prisms: Sendable {
        public let circle: Prism<Figure, Double> = CoreFP.prism(
            preview: { s in guard case .circle(let a) = s else { return nil }; return a },
            review: Figure.circle
        )
        public let rectangle: Prism<Figure, (Double, Double)> = CoreFP.prism(
            preview: { s in guard case .rectangle(let v0, let v1) = s else { return nil }; return (v0, v1) },
            review: { (t: (Double, Double)) in Figure.rectangle(t.0, t.1) }
        )
        public let empty: Prism<Figure, Void> = CoreFP.prism(
            preview: { s in guard case .empty = s else { return nil }; return () },
            review: { (_: Void) in Figure.empty }
        )
    }
    public static var prism: Prisms { Prisms() }

    // One plain property per case — no @dynamicMemberLookup involved:
    public var circle: Double? { Self.prism.circle.preview(self) }
    public var rectangle: (Double, Double)? { Self.prism.rectangle.preview(self) }
    public var empty: Void? { Self.prism.empty.preview(self) }

    public enum Cases: CoreFP.CaseMatchable {
        public typealias Subject = Figure
        case circle, rectangle, empty
        public func matches(_ value: Figure) -> Bool { /* switch */ }
    }
    public func `is`(_ c: Cases) -> Bool { c.matches(self) }
}
```

Multi-payload cases (like `.rectangle`) get an **unlabeled** tuple type — access with `.0`/`.1`, not the original parameter labels.

`prism` is always computed: Swift forbids `static let` in any generic context, which includes generic enums (`Loading<Success, Failure>`) and enums nested in a generic type.

**Usage:**

```swift
let s = Figure.circle(3.14)

s.circle                                    // Optional(3.14) — plain per-case property
s.rectangle                                 // nil
Figure.prism.circle.preview(s)               // Optional(3.14) — the same thing, via the explicit prism
Figure.prism.circle.set(s, 5.0)             // Figure.circle(5.0)
Figure.prism.circle.over({ $0 * 2 })(s)    // Figure.circle(6.28)

// Case-name queries — no need to construct dummy payloads:
s.is(.circle)                               // true
s.is(.rectangle)                            // false
Figure.Cases.allCases                        // [.circle, .rectangle, .empty]
```

**Slicing the output**

Use `PrismsOptions` to opt out of pieces you don't need:

```swift
@Prisms(.cases) enum OnlyCases { case a }         // only the `Cases` enum + is(_:)
@Prisms(.prisms) enum OnlyPrisms { case a(Int) }  // only the `Prisms` struct + `static prism` + per-case properties + Prismatic
```

**Polymorphic `HasCases`**

The `CoreFP.HasCases` protocol lets generic code write `value.is(.someCase)` against any type whose nested `Cases` enum is a `CaseMatchable`. `@Prisms` doesn't automatically add the conformance (Swift's extension-macro role can't reach into nested types), but you can opt in for any file-level or non-private-nested type:

```swift
extension Figure: HasCases {}  // typealias inferred from the nested `Cases` enum

func currentIsFirstCase<T: HasCases>(_ value: T) -> Bool {
    T.Cases.allCases.first.map { value.is($0) } ?? false
}
```

The built-in types `Loading`, `Either`, `Validation`, `Optional`, and `Result` all conform out of the box.

#### `@ApplyOptics`: optics for a whole nested tree

`@ApplyOptics` is a kind-dispatched drop-in for `@Lenses` (on structs) and `@Prisms` (on enums). With `recursively: true` it applies to every nested struct and enum at any depth, so an entire state tree gains composable optics from a single annotation. Put `@Lenses` / `@Prisms` on a nested type to customise just that node, another `@ApplyOptics(...)` to re-root a subtree, and `@NoOptics` to cut a node (and everything below it) out.

```swift
@ApplyOptics(recursively: true)
struct Game {
    var title = ""
    struct Player { var score = 0 }
    enum Phase { case lobby; case playing(Int) }
    @NoOptics struct Cache { var hits = 0 }   // no optics here, nor below
}

Game.lens.title             // Lens<Game, String>
Game.Player.lens.score      // Lens<Game.Player, Int>
Game.Phase.prism.playing    // Prism<Game.Phase, Int>
```

#### Nesting — the primary motivation

Both macros attach members (plus an extension: `Sendable` for `@Lenses`, `Prismatic` for `@Prisms`), so they work on types nested inside other types, which is the typical pattern in unidirectional architectures where a `Reducer` owns its `State` and `Action`. They can't be applied to a type declared inside a function body (Swift forbids extension macros there):

```swift
struct Reducer {
    @Lenses(init: .internal)
    struct State {
        let userName: String
        var score: Int
        var isActive = false
    }

    @Prisms
    enum Action {
        case updateName(String)
        case incrementScore(Int)
        case reset
    }
}

// State lenses — functional updates, no mutation:
let state = Reducer.State(userName: "Alice", score: 0)
Reducer.State.lens.userName.set(state, "Bob")       // State(userName: "Bob", score: 0, isActive: false)
Reducer.State.lens.score.over({ $0 + 10 })(state)  // State(userName: "Alice", score: 10, isActive: false)

// Action prisms — safe extraction and inspection:
let action = Reducer.Action.updateName("Bob")
action.updateName                                    // Optional("Bob")
action.incrementScore                                // nil
Reducer.Action.prism.updateName.preview(action)      // Optional("Bob")

// The generated optics are regular Lens / Prism values — compose and lift them
// exactly as shown in earlier sections. For example, if another struct wraps
// Reducer.State, its lens composes with the generated ones:
//   lens(\AppState.game) >>> Reducer.State.lens.score  // Lens<AppState, Int>
//   lens(\AppState.game).compose(Reducer.State.lens.score)  // same, no operators
```

#### Type annotation note

Properties with literal defaults (`0`, `3.14`, `"hello"`, `true`) have their types inferred automatically. For any other default, add an explicit type annotation:

```swift-sketch
var timeout: Duration = .seconds(30)    // explicit annotation required
var retryPolicy: RetryPolicy = .exponential  // explicit annotation required
```

#### Access-level restriction

`@Lenses` and `@Prisms` **cannot** be applied to `private` declarations — the macros refuse with a compile-time error. `private`'s type-scope semantics break the generated namespace (its stored `Lens<Host, X>` / `Prism<Host, X>` fields can't be exposed outside the host's body). Use `fileprivate` instead; it's functionally identical at file scope and works everywhere the macros need to. `fileprivate`, `internal`, `package`, `public`, and `open` all work uniformly, at file level or nested. The same rule applies to `@Iso`, `@DeriveMonoid`, `@Mock`, and `@Witness`.

#### Built-in prisms

The following library types already ship with `@Prisms`-equivalent surface (hand-written to match what the macro would emit), so you can use them out of the box without applying the macro yourself:

| Type | `Type.prism.…` | plain property (`value.…`) | `value.is(.…)` |
|---|---|---|---|
| `Either<A, B>` | `.left`, `.right` | ✓ | ✓ |
| `Validation<E, A>` | `.failure`, `.success` | ✓ | ✓ |
| `Loading<S, F>` | `.idle`, `.loading`, `.loaded`, `.failed` | ✓ | ✓ |
| `Optional<Wrapped>` | `.some`, `.none` | ✓ | ✓ |
| `Result<S, F>` | `.success`, `.failure` | ✓ | ✓ |

All five conform to `HasCases`, so they work with the polymorphic `is(_:)` extension. The legacy `isSuccess` / `isFailure` / `isSome` / `isNone` / `isLeft` / `isRight` boolean accessors have been removed — use `value.is(.success)` (etc.) instead.

#### `@Iso` — struct ↔ tuple conversion

`@Iso` generates a total, sound `static var iso` between a struct and a structural representation of its stored fields — the field's type itself for a single-field struct, or a tuple of the field types otherwise. It always round-trips through the struct's memberwise initialiser, so there's nothing to get wrong.

```swift
@Iso struct Point { var x: Int; var y: Int }
// Point.iso : Iso<Point, (Int, Int)>

@Iso struct Celsius { var value: Double }
// Celsius.iso : Iso<Celsius, Double>
```

```swift
Point.iso.get(Point(x: 1, y: 2))     // (1, 2)
Point.iso.reverseGet((3, 4))         // Point(x: 3, y: 4)
```

`@Iso(Other.self)` maps field-by-field through another type's memberwise initialiser instead of a tuple — convenient, but unverified: the macro can only see `Other`'s name, not its fields, so a shape mismatch surfaces as a compile error in the generated code rather than a clean diagnostic.

```swift
@Iso struct PointDTO { var x: Int; var y: Int }

@Iso(PointDTO.self)
struct LabeledPoint { var x: Int; var y: Int }
// LabeledPoint.iso : Iso<LabeledPoint, PointDTO>
```

For the library's own generic `Newtype`, prefer its built-in `Newtype.iso` (see [Newtype — Branded Values](#newtype--branded-values)) rather than applying this macro.

#### `@DeriveMonoid` — fieldwise `Monoid`

`@DeriveMonoid` derives `Semigroup` + `Monoid` for a struct as the **product** of its stored properties. Every stored property must itself already be a `Monoid` — `combine` combines the two values field-by-field, and `identity` is each field's `identity`:

```swift
@DeriveMonoid
struct Stats {
    var clicks: Int.Monoids.Sum
    var ok: Bool.Monoids.And
}
```

```swift
Stats.identity.clicks.rawValue   // 0
Stats.identity.ok.rawValue       // true

let combined = Stats.combine(
    Stats(clicks: .init(2), ok: .init(true)),
    Stats(clicks: .init(3), ok: .init(false))
)
combined.clicks.rawValue   // 5     — summed
combined.ok.rawValue       // false — AND-ed

mconcat([
    Stats(clicks: .init(1), ok: .init(true)),
    Stats(clicks: .init(4), ok: .init(true)),
]).clicks.rawValue   // 5
```

A bare `Int` field won't work — `Int` has no single canonical monoid; wrap it as `Int.Monoids.Sum` / `Int.Monoids.Product` first (see [Neutral element when joining (Monoid)](#neutral-element-when-joining-monoid)). The struct must keep its memberwise initialiser (synthesised or written).

#### `@Mock` — configurable protocol test doubles

`@Mock` emits a `struct <Protocol>Mock: <Protocol>` (wrapped in `#if DEBUG`) whose every requirement is backed by a stored `wrapped…` closure. The memberwise init lets a test override just the requirements it cares about; every other requirement defaults to a closure that crashes loudly the moment it's called un-overridden.

```swift
@Mock
protocol Service {
    func fetch(id: String) -> AnyPublisher<[Item], any Error>
    var isReady: Bool { get }
}
```

expands (behind `#if DEBUG`) to:

```swift-sketch
struct ServiceMock: Service {
    var wrappedFetch: (String) -> AnyPublisher<[Item], any Error>
    var wrappedIsReady: () -> Bool

    init(
        fetch: @escaping (String) -> AnyPublisher<[Item], any Error> = { _ in CoreFP.fail("Mock function not implemented for test case")() },
        isReady: @escaping () -> Bool = { CoreFP.fail("Mock function not implemented for test case")() }
    ) { self.wrappedFetch = fetch; self.wrappedIsReady = isReady }

    func fetch(id: String) -> AnyPublisher<[Item], any Error> { wrappedFetch(id) }
    var isReady: Bool { wrappedIsReady() }
}
```

```swift
// Only `isReady` is overridden; `fetch` defaults to a crashing stub but is never called:
let mock = ServiceMock(isReady: { false })
```

`{ get set }` properties generate a getter closure plus a `wrapped<Name>Set` closure; overloaded methods are disambiguated only on collision (by argument labels, then by labels and parameter types). A class-bound (`AnyObject`) protocol gets a `final class` mock and a `Sendable` protocol gets `@Sendable` closures. Typed `throws(E)`, `rethrows`, `{ get async throws }` getters, `inout`, variadic, `@autoclosure`, non-escaping closure and unnamed `_:` parameters are all handled. Protocol inheritance (beyond `Sendable`/`AnyObject`), `mutating`/`static`/`init`/`subscript` requirements, non-erasable generics and `private` protocols are diagnosed rather than silently mishandled.

#### `@Witness` — protocols as first-class values

`@Witness` generates a **witness** struct — the protocol's requirements as `@Sendable` closure fields and nothing else — so a conforming instance becomes a plain, composable value instead of an existential (`any P`). This is the building block for dependency injection: construct, stub, and compose witnesses like any other value.

```swift
@Witness
public protocol Repository<Item> {
    associatedtype Item
    associatedtype Failure: Error
    func fetch(id: String) async -> Result<Item, Failure>
    func all() -> [Item]
    var count: Int { get }
}
```

expands to:

```swift-sketch
public struct RepositoryWitness<Item, Failure: Error>: Sendable {
    public var fetch: @Sendable (String) async -> Result<Item, Failure>
    public var all: @Sendable () -> [Item]
    public var count: @Sendable () -> Int
    // memberwise init, plus an init from any conforming `Base: Repository & Sendable`
}

public extension Repository where Self: Sendable {
    var witness: RepositoryWitness<Item, Failure> { .init(self) }
}
```

```swift
struct RepoError: Error, Sendable {}
struct MemoryRepo: Repository, Sendable {
    var store: [String: Int]
    func fetch(id: String) async -> Result<Int, RepoError> { store[id].map { .success($0) } ?? .failure(RepoError()) }
    func all() -> [Int] { Array(store.values) }
    var count: Int { store.count }
}

let w = MemoryRepo(store: ["a": 1]).witness   // RepositoryWitness<Int, RepoError>
```

`{ get set }` properties become a getter thunk plus a `set<Name>` closure; because the protocol setter is `mutating`, the from-instance `init` and `.witness` convenience are gated to `where …: AnyObject` whenever a settable member exists. Protocol inheritance composes by name (`ChildWitness` gains a `parent: ParentWitness` field, provided the parent is also `@Witness`); marker and stdlib parents (`Sendable & AnyObject`, `Equatable`, `Codable`, …) aren't composed, and a parent with `{ get set }` requirements needs a class-bound child (`protocol Child: AnyObject, Parent`). Typed `throws(E)` and `{ get async throws }` getters are preserved. Requirements mentioning `Self`, `rethrows` requirements, variadic parameters, non-erasable generics and `private` protocols are diagnosed.

---

### Property-Based Testing (Gen)

`Gen<R, Value>` is a composable random-value generator, this library's counterpart to QuickCheck's `Gen a` (Haskell) and ScalaCheck's `Gen[A]`. It's defined as a `Stateful` computation threading a random-number generator:

```swift-sketch
public typealias Gen<R: RandomNumberGenerator & Sendable, Value> = Stateful<R, Value>
```

A generator is only a description, `(inout R) -> Value`. There is deliberately no runner that creates the RNG for you: you inject it. Because it's just `Stateful` under the hood, `Gen` inherits every Functor/Applicative/Monad operation (and every `Stateful` transformer combination) for free. Use `AnyRandomNumberGenerator` to erase the RNG type.

**Primitives:**

```swift
typealias G<V> = Gen<SplitMix64, V>

let die: G<Int>     = .int(in: 1...6)
let coin: G<Bool>   = .bool()
let userId: G<UUID> = .uuid()
```

**Composing generators** with `map` / `flatMap` / `zip`, exactly like any other monad in this library:

```swift
let die: G<Int> = .int(in: 1...6)
let sumOfTwoDice = G.zip(die, die).map { $0 + $1 }   // 2...12

struct Customer: Sendable { let id: UUID; let name: String; let age: Int }

let customerGen: G<Customer> = G.zip(
    .uuid(),
    .string(of: .letter(), count: .int(in: 3...8)),
    .int(in: 0...120)
).map { (t: (UUID, String, Int)) in Customer(id: t.0, name: t.1, age: t.2) }
```

Other combinators include `.array(ofCount:)`, `.optional()`, `.one(of:)` (uniform choice over a `NonEmpty` list of generators), and `.frequency(_:)` (weighted choice). See `Sources/DataStructure/Gen/` for the full set.

**Running a generator** with an RNG you provide:

```swift
let die: G<Int> = .int(in: 1...6)
var rng = SplitMix64(seed: 42)
let value = die.run(&rng)                      // deterministic: same seed, same value
let many  = die.array(ofCount: 100).run(&rng)  // deterministic sequence, replayable in a failing test

var system = SystemRandomNumberGenerator()
let liveDie: Gen<SystemRandomNumberGenerator, Int> = .int(in: 1...6)
let live = liveDie.run(&system)                // entropy, at the edge of the program
```

`SplitMix64` is a small seedable PRNG, so a failing property-test case can be replayed exactly by rerunning with the same seed.

---

## Coming from Haskell

A quick-reference for readers coming from Haskell's `base` and common libraries. This is a compact, at-a-glance table — see the linked subsection above for the full treatment of each type or operator.

| Haskell | This library | Notes |
|---|---|---|
| `Maybe a` | `Optional<A>` | Swift's built-in optional, extended with full Functor/Applicative/Monad — see [Map (Functor)](#map-functor) |
| `Either a b` | `Either<A, B>` | Unconstrained sum type, no `Error` requirement on either side — see [SumType2](#sumtype2--shared-interface-for-two-case-types) |
| `[a]` | `[A]` / `Array<A>` | Swift's built-in array — nondeterminism via `flatMap` — see [FlatMap (Monad)](#flatmap-monad) |
| `IO a` | _not modelled_ | This library doesn't wrap side effects in a type; effects are pushed to the boundary instead — see [Concurrency: Sendable-First](#concurrency-sendable-first) |
| `Reader r a` | `Reader<Env, A>` | Dependency injection monad — see [Covariance, contravariance, and contramap](#covariance-contravariance-and-contramap) |
| `Writer w a` | `Writer<Log, A>` | Append-as-you-go monad, also a Comonad (the `Env` comonad `(a, w)`) — see [Comonad (Extend)](#comonad-extend) |
| `State s a` | `Stateful<S, A>` | Named `Stateful` (not `State`) to avoid clashing with SwiftUI — see [Types](#types) |
| `Semigroup` | `Semigroup` | Same name, same law — see [Joining things together (Semigroup)](#joining-things-together-semigroup) |
| `Monoid` | `Monoid` | Same name, same law — see [Neutral element when joining (Monoid)](#neutral-element-when-joining-monoid) |
| `newtype` | `Newtype<Tag, RawValue>` | Phantom-tagged wrapper instead of a language keyword — see [Newtype — Branded Values](#newtype--branded-values) |
| `Gen a` (QuickCheck) | `Gen<R, A>` (`Stateful<R, A>`, `R: RandomNumberGenerator & Sendable`) | Composable random generator, run with an explicitly injected RNG: `gen.run(&rng)` — see [Property-Based Testing (Gen)](#property-based-testing-gen) |
| `ReaderT r m a` / `ExceptT e m a` / `MaybeT m a` / `WriterT w m a` / `StateT s m a` | `ReaderTArray`, `PublisherTEither`, `StatefulTOptional`, … | The generated structs (see [Stacking Effects](#stacking-effects-monad-transformers)): lift with `.readerT` / `.publisherT` / …, unwrap with `.rawValue`; escape hatches `mapReaderT` / `mapExceptT` / `mapMaybeT` / `mapWriterT` / `mapStateT` |
| `Validation e a` (validation package) | `Validation<E, A>` | Accumulating applicative, no monad |
| `These a b` | `These<A, B>` | Inclusive-or |
| `NonEmpty a` | `NonEmpty<A>` | Non-empty sequence |
| `RemoteData` (PureScript) | `Loading<Success, Failure>` | Async lifecycle with stale values |
| `fmap` / `<$>` | `<£>` | Functor map, function on the left (`<&>` is `Data.Functor.<&>`, container on the left) |
| `<$` / `$>` | `<£` / `£>` | Replace with a constant |
| `<*>` | `<*>` | Applicative apply — same symbol |
| `>>=` | `>>-` | Monadic bind (renamed — Swift reserves `>>=` for bit-shift-assign) |
| `=<<` | `-<<` | Monadic bind, function on the left |
| `>=>` | `>=>` | Kleisli composition — same symbol |
| `<\|>` | `<\|>` | Alternative / choice — same symbol |
| `<>` | `<>` | Semigroup append — same symbol |
| `$` | `<\|` | Function application, function on the left |
| `&` | `\|>` | Function application, value on the left |
| `.` | `<<<` | Composition, right to left (`>>>` is Haskell's `Control.Arrow` `>>>`, left to right) |

See the [Operator Reference](#operator-reference) for the complete operator list and [Types](#types) for per-type reference pages.

---

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide (setup, branch naming, and tooling). The architecture has a few firm rules to keep the library consistent:

- Every operator must delegate to a named function in the core module — never implement logic directly inside an operator definition
- Every directional operator has a flipped counterpart (e.g., `<£>` ↔ `<&>`); both must be added in the same commit
- Core modules (`CoreFP`, `DataStructure`) never use custom operators; operators live only in the operator modules and delegate to a named core function. `CoreFPTests` / `DataStructureTests` use named functions only, `CoreFPOperatorsTests` / `DataStructureOperatorsTests` test the operator symbols, and every operation needs both
- Haskell is the source of truth for semantics: `<*>` equals `ap` wherever there is a monad, and a stack only gets `flatMap` / `>>-` where Haskell's `transformers` defines a lawful monad
- Transformer stacks under `Sources/*/Transformer/Generated/` are generated by `Scripts/GenerateTransformers.swift`: edit the table or templates and regenerate, never the generated files (see CONTRIBUTING.md)

To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes, including tests
4. Run the full test suite to confirm nothing is broken
5. Submit a pull request

See [CHANGELOG.md](CHANGELOG.md) for the history of released versions.

## Testing

The library verifies functional programming laws (Functor, Applicative, Monad laws) and all operator behaviours across all types and their transformer combinations.

Test targets: `CoreFPTests`, `CoreFPOperatorsTests`, `DataStructureTests`, `DataStructureOperatorsTests`, `FPMacrosTests`.

```bash
# Run all tests
swift test

# Run a specific test by name (Swift Testing uses / as separator)
swift test --filter "EitherFunctorTests/flatMap"

# Run all tests whose name contains a word (matches across targets)
swift test --filter "CoreFP"
```

## Platform Support

| Platform | Minimum Version      |
|----------|----------------------|
| macOS    | 10.15+               |
| iOS      | 13.0+                |
| tvOS     | 13.0+                |
| watchOS  | 6.0+                 |
| visionOS | 1.0+                 |
| Linux    | Swift 6.3+ toolchain |
| Windows  | Swift 6.3+ toolchain |
| Android  | Swift 6.3+ toolchain |

Combine-based features (`Publisher` extensions, `PublisherT*` stacks) and the SwiftUI `Binding` bridge are Apple-only (`#if canImport(Combine)` / `canImport(SwiftUI)`) and available from the package minimums above. The `ReaderTPublisher`, `StatefulTPublisher` and `WriterTPublisher` stacks require macOS 13 / iOS 16 / tvOS 16 / watchOS 9. Everything else builds and is tested on Linux, Windows, and Android.

## License

Apache-2.0
