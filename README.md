# FP

FP is a Swift library that brings functional programming patterns to your codebase in a composable, type-safe way. It extends Swift's built-in types (`Optional`, `Result`, `Array`, `Publisher`, async/await `Task`, `AsyncSequence`) and introduces new data structures that make common patterns — error handling, dependency injection, state threading, validation — explicit, predictable, and easy to test.

The library draws from Haskell and Scala Cats conventions and is designed to be used incrementally: start with just the core extensions and adopt more as your comfort grows.

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

In Mathematics, a **Semigroup** is any type where two instances can be combined into one of the same type. Two Strings combine with `+` resulting in a single String, two arrays combine with `+` also to form a single array. In both cases, the resulting value will contain elements from the left and elements from the right, but the main idea is that `(String, String) -> String` and `(Array, Array) -> Array`. Most numbers can combine in two different ways, however, because you can sum them or multiply them, and in both cases you start with two numbers and end up with a single value of the same type. Booleans also combine with `&&` or `||`.

Curiosity: lasagna is a semigroup, because putting one lasagna on top of another gives you lasagna.

In this library you will find a `protocol Semigroup` which is implemented by several types like `String` and `Array`, and represent the operation of joining two into one. For numbers and Bool, continue reading the next topic.

### Neutral element when joining  (Monoid)

If `Semigroup` allows to combine two things together, `Monoid` extends that protocol with one extra requirement: there should be a neutral element that, when joined with any other instance of that type, keeps it unchanged (regardless of the order). That sounds much more complicated than what it is, examples for the rescue. Remember that String is a semigroup, because `"Hello" + " World" -> "Hello World"`? Now, take empty string `""`, when combine from the left (`"" + "some other string"`) or from the right (`"some other string" + ""`) keeps `"some other string"` unchanged. That means `String` is a monoid, because it's a semigroup with a neutral element. `Array` has a neutral element too, the empty array `[]`. Int and other numbers, are semigroup and monoid, but there's a problem: they have multiple implementations of monoid because you can sum two numbers (`4 + 2 -> 6`) or multiply two numbers (`4 * 2 -> 8`), and in both cases you start with two instances (4 and 2) and end up with a single instance that for sum will be 6 or for multiplication will be 8. For sum, the neutral element is 0, as summing zero to anything keeps that unchanged, while for multiplication the neutral element is 1. Now, Swift doesn't allow to implement the `protocol Monoid` twice, in two completely different ways, so instead of `extension Int: Monoid`, we make a boxing type for each instance, meaning `Int.Monoids.Sum(5)`, which is the sum instance of monoid for ints, while `Int.Monoids.Product(5)` wraps the Int in a multiplication instance of monoid. Same thing for types like `UInt`, `Float`, `CGFloat` and others, while `Bool.Monoids.And` and `Bool.Monoids.Or` will have instances of monoids for operations `&&` (with neutral element `true`) and `||` (neutral element `false`) respectively.

By-the-way, neutral element is called `identity`, and can now be found in `String.identity`, `Array.identity`, `Int.Monoids.Sum.identity`, `Bool.Monoids.And.identity` and similars.

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

This library makes the concept concrete via the `Reader` type (a wrapper around `(Environment) -> Output`):

```swift
let validate: Reader<String, Bool> = Reader { $0.count > 3 }

// contramapEnvironment adapts the input type
let validateInt: Reader<Int, Bool> = validate.contramapEnvironment { String($0) }
```

#### Profunctor and dimap

A **Profunctor** is a type that is covariant in one parameter and contravariant in another. Plain functions are the textbook example: `(A) -> B` can be mapped on the output (covariant in `B`) and contramapped on the input (contravariant in `A`). That makes functions profunctors.

`dimap` does both in one call:

```swift
let validate: Reader<String, Bool> = Reader { $0.count > 3 }

// adapt both the input and the output at once
let validateAndDescribe: Reader<Int, String> = validate.dimap(
    { String($0) },      // Int → String (input adapter)
    { $0 ? "ok" : "too short" }  // Bool → String (output adapter)
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

### Zip / Apply

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

### FlatMap

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

Composing a `Lens` with a `Prism` yields an `AffineTraversal` — a focus that may or may not be present, depending on which enum case is active (see the next section).

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

---

### Functional Getter / Setter for Enums (Prism)

Where a `Lens` works on structs (where every field is always present), a **Prism** works on enums (where only one case is active at a time). A Prism focuses on a specific case and lets you extract or construct values for that case.

It has two operations:
- `preview` — tries to extract the associated value; returns `nil` if the enum is a different case
- `review` — constructs an enum value from the focused type

```swift
enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
}

let circlePrism = prism(
    preview: { if case .circle(let r) = $0 { return r } else { return nil } },
    review:  Shape.circle
)

circlePrism.preview(.circle(5.0))        // Optional(5.0)
circlePrism.preview(.rectangle(3, 4))    // nil
circlePrism.review(7.0)                  // Shape.circle(7.0)
circlePrism.over { $0 * 2 }(.circle(5)) // Shape.circle(10.0)
circlePrism.over { $0 * 2 }(.rectangle(3, 4))  // Shape.rectangle(3, 4) — unchanged
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

**Composing Prisms with Lenses**

Prisms compose with other prisms, and with lenses. Composing a `Prism` with a `Lens` gives an `AffineTraversal` — an optic that *may or may not* have a focus depending on which case is active:

```swift
enum App { case loggedIn(User); case guest }
struct User { var address: Address }
struct Address { var city: String }

let loggedInPrism: Prism<App, User> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review:  App.loggedIn
)

let userCityTraversal = loggedInPrism >>> ^\User.address >>> ^\Address.city
// AffineTraversal<App, String>

userCityTraversal.preview(.loggedIn(User(address: Address(city: "Paris"))))  // Optional("Paris")
userCityTraversal.preview(.guest)  // nil
```

An `AffineTraversal` has `preview` for optional extraction, `set` for conditional update (leaves the value unchanged if the focus is absent), and `over` for conditional transformation.

#### Prism operators _(optional, requires CoreFPOperators)_

`>>>` and `<<<` work for Prism composition the same way as for Lens:

```swift
// Prism >>> Prism → Prism
let deepCasePrism = outerPrism >>> innerPrism

// Prism >>> Lens → AffineTraversal
let cityInLoggedInUser = loggedInPrism >>> ^\User.address >>> ^\Address.city
```

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
