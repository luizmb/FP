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
```

The same pattern applies to `UInt`, `Float`, `Double`, `CGFloat`, and all other numeric types. Float literals work too:

```swift
Double.Monoids.Sum.combine(1.5, 2.5)                       // Sum(4.0)
mconcat([1.0, 2.5, 0.5] as [Double.Monoids.Sum]).rawValue  // 4.0
```

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

### Utilities

**Function composition** — `>>>` and `<<<`

```swift
let trim:       (String) -> String = { $0.trimmingCharacters(in: .whitespaces) }
let uppercased: (String) -> String = { $0.uppercased() }
let exclaim:    (String) -> String = { $0 + "!" }

let shout = trim >>> uppercased >>> exclaim   // left-to-right
shout("  hello  ")   // "HELLO!"

let shout2 = exclaim <<< uppercased <<< trim  // right-to-left, equivalent
shout2("  hello  ")  // "HELLO!"
```

**Function application** — `£` / `<|` and `|>`

```swift
uppercased £ "hello"                   // "HELLO"  — fn left
uppercased <| "hello"                  // "HELLO"  — fn left (ASCII alternative)
"hello" |> uppercased                  // "HELLO"  — value left (pipe)
"  hello  " |> trim |> exclaim        // "hello!" — pipeline
```

**Core building blocks**

```swift
id("hello")                                       // "hello" — identity
const(42)("anything")                             // 42      — ignore second argument
flip(-)( 3, 10)                                   // 7       — swap argument order
curry { $0 + $1 }(1)(2)                           // 3       — (A, B) -> C into A -> B -> C
uncurry { a in { b in a + b } }((1, 2))           // 3       — inverse of curry
partialApply({ a, b in a + b }, 10)(5)            // 15      — fix first argument
withArg("hello")(uppercased)                      // "HELLO" — argument-first application
```

**fanout** — apply multiple functions to the same input, collect results into a tuple:

```swift
let (upper, count, first) = fanout(uppercased, \.count, \.first)("hello")
// ("HELLO", 5, Optional("h"))
```

**join and void** — flatten nested containers or discard values:

```swift
join([[1, 2], [3, 4]])               // [1, 2, 3, 4] — [[A]] → [A]
join(Optional(Optional(42)))         // Optional(42)  — A?? → A?
join(Result<Result<Int,E>,E>.success(.success(42)))  // .success(42)

void([1, 2, 3])                      // [(), (), ()]  — discard values, keep structure
void(Optional(42))                   // Optional(())
```

**Tuple utilities**

```swift
mapTuple2(uppercased)("hello", "world")     // ("HELLO", "WORLD")
mapTuple3({ $0 * 2 })(1, 2, 3)            // (2, 4, 6)
tuple(1, "hello")                           // (1, "hello")
untuple { $0 + $1 }((1, 2))               // 3  — tuple-argument → two-argument
```

**Type casting** — curried, for pipelines:

```swift
// cast — guaranteed cast (value must already be that type, no crash)
cast(String.self)("hello")         // "hello"

// castOptionally — safe cast, returns nil on mismatch
castOptionally(Int.self)("hello")  // nil
castOptionally(Int.self)(42)       // Optional(42)
```

**lazy / unlazy** — defer and force evaluation:

```swift
let later: () -> Int = lazy(expensiveComputation())  // not evaluated yet
unlazy(later)                                         // forces it
```

**Boolean predicates** — curried, for point-free composition:

```swift
[1, 2, 3, 2].filter(equals(2))       // [2, 2]
[1, 2, 3, 2].filter(notEquals(2))    // [1, 3]
[1, 2, 3, 4].filter(not { $0 % 2 == 0 })  // [1, 3]
[0, 1, 2, -1].filter(and({ $0 % 2 == 0 }, { $0 > 0 }))  // [2]
[0, 1, 2, -1].filter(or({ $0 == 0 }, { $0 > 1 }))        // [0, 2]
```

**`Mutable`** — builder-pattern copy for value types:

```swift
struct Config: Mutable { var host: String; var port: Int }

let base = Config(host: "localhost", port: 8080)
let dev  = base.mutate { $0.port = 3000 }     // Config(host: "localhost", port: 3000)
```

**`ignore` / `absurd`** — structural helpers:

```swift
[1, 2, 3].map(ignore)   // [(), (), ()]
// absurd(n) — eliminate the Never type in impossible branches
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
| `>>>` | `<<<` | Function / optics composition — left-to-right / right-to-left | Functions, `Lens`, `Prism`, `AffineTraversal` |
| `£` / `<\|` | `\|>` | Function application — fn left / value left | Any function |
| `<\|>` | — | Alternative / choice | `Optional`, `Array`, `Result`, `Publisher`, `DeferredTask`, `DeferredStream` |
| `<>` | — | Semigroup append | `String`, `Array`, `Optional`, `Dictionary`, `Set`, `Result`, `Int.Monoids.*`, `Bool.Monoids.*`, … |
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

#### DataStructure

| Type | Description |
|------|-------------|
| [Either](docs/types/Either.md) | Unconstrained sum type — both sides are equal citizens, no `Error` requirement |
| [Validation](docs/types/Validation.md) | Accumulating applicative — errors collect instead of short-circuiting |
| [Reader](docs/types/Reader.md) | Dependency injection monad — wraps `(Environment) -> Output` |
| [Stateful](docs/types/Stateful.md) | State threading monad — wraps `(inout S) -> A` |
| [Writer](docs/types/Writer.md) | Append-as-you-go monad — produces a value alongside an accumulated log |

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
