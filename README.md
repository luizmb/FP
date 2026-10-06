# FP

FP is a Swift library for building programs out of small, predictable pieces. It adds useful operations to the types you already use (`Optional`, `Result`, `Array`, `Dictionary`, functions, Combine's `Publisher`) and brings a few new ones for things Swift doesn't model directly: errors you want to collect instead of stopping at the first, data that is still loading, dependencies you want to inject, deep updates to nested structs.

You don't need any background in functional programming. This README starts with code that looks like everyday Swift and adds one idea at a time, each building on the ones before. Everything is a plain named function; the symbolic operators (`>>-`, `<£>`, …) are an optional extra, covered in their own part at the end.

[![Tests](https://github.com/luizmb/FP/actions/workflows/ci.yml/badge.svg)](https://github.com/luizmb/FP/actions)
[![Documentation](https://img.shields.io/badge/docs-online-blue)](https://ios.lu/FP)
[![Swift 6.3+](https://img.shields.io/badge/swift-6.3%2B-orange)](https://swift.org)

**[→ Full API Documentation](https://ios.lu/FP)** · [Installation](#installation) · [Quick Start](#quick-start)

## Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [1. More from the types you already use](#1-more-from-the-types-you-already-use)
  - [Handling a missing value (`fold`)](#handling-a-missing-value-fold)
  - [Transforming what's inside (`map`)](#transforming-whats-inside-map)
  - [Chaining steps that can fail (`flatMap`)](#chaining-steps-that-can-fail-flatmap)
  - [Combining independent values (`zip`)](#combining-independent-values-zip)
  - [All or nothing (`traverse` and `sequence`)](#all-or-nothing-traverse-and-sequence)
  - [Falling back to another value (`alt`)](#falling-back-to-another-value-alt)
  - [Safe collection access](#safe-collection-access)
  - [Small helpers](#small-helpers)
- [2. New types for your domain](#2-new-types-for-your-domain)
  - [Either: one thing or another](#either-one-thing-or-another)
  - [Validation: collect every error](#validation-collect-every-error)
  - [Loading: data that takes time](#loading-data-that-takes-time)
  - [Newtype: an `Int` that isn't just an `Int`](#newtype-an-int-that-isnt-just-an-int)
  - [IdentifiedArray: ordered, with fast lookup by id](#identifiedarray-ordered-with-fast-lookup-by-id)
  - [Converting between types](#converting-between-types)
  - [All types](#all-types)
- [3. Combining values (Semigroup and Monoid)](#3-combining-values-semigroup-and-monoid)
  - [Joining two values (Semigroup)](#joining-two-values-semigroup)
  - [A neutral starting point (Monoid)](#a-neutral-starting-point-monoid)
- [4. Updating nested data (optics)](#4-updating-nested-data-optics)
  - [Structs: Lens](#structs-lens)
  - [Enums: Prism](#enums-prism)
  - [Paths that may not exist: AffineTraversal](#paths-that-may-not-exist-affinetraversal)
  - [Collections: `ix`](#collections-ix)
  - [Two-way conversions: Iso](#two-way-conversions-iso)
  - [Identity optics (`.id`)](#identity-optics-id)
  - [Chaining transformations (Endo)](#chaining-transformations-endo)
  - [Updating in place without copies (EndoMut)](#updating-in-place-without-copies-endomut)
  - [Generating optics (and more) with macros](#generating-optics-and-more-with-macros)
- [5. Effects as values](#5-effects-as-values)
  - [Dependencies: Reader](#dependencies-reader)
  - [State: Stateful](#state-stateful)
  - [Logs: Writer](#logs-writer)
  - [Random test data: Gen](#random-test-data-gen)
  - [Combining effects (transformer stacks)](#combining-effects-transformer-stacks)
- [6. Building functions from functions](#6-building-functions-from-functions)
  - [Composing and adapting functions](#composing-and-adapting-functions)
  - [Functions inside containers (`apply`)](#functions-inside-containers-apply)
- [7. Operators (optional)](#7-operators-optional)
  - [Joining: `<>`](#joining-)
  - [Mapping: `<£>`, `<&>`, `£>`, `<£`](#mapping----)
  - [Chaining: `>>-`, `-<<`, `>=>`, `<=<`](#chaining------)
  - [Applying wrapped functions: `<*>`, `*>`, `<*`](#applying-wrapped-functions---)
  - [Choosing: `<|>`](#choosing-)
  - [Composing functions and optics: `>>>`, `<<<`, `^`](#composing-functions-and-optics---)
  - [Applying a function: `<|`, `|>`](#applying-a-function--)
  - [Extending: `->>`, `<<-`](#extending----)
  - [Ranges: `±`, `≅`](#ranges--)
  - [Operator Reference](#operator-reference)
- [Reference](#reference)
  - [Modules](#modules)
  - [Concurrency: Sendable-first](#concurrency-sendable-first)
  - [SumType2: one interface for two-case types](#sumtype2-one-interface-for-two-case-types)
  - [Coming from Haskell](#coming-from-haskell)
- [Learning more](#learning-more)
- [Contributing](#contributing)
- [Testing](#testing)
- [Platform Support](#platform-support)
- [License](#license)

## Installation

Add the package with Swift Package Manager:

```swift-sketch
// Package.swift
dependencies: [
    .package(url: "https://github.com/luizmb/FP.git", from: "3.0.0")
]
```

```swift-sketch
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "FP", package: "FP")
    ]
)
```

Then import it:

```swift
import FP
```

`FP` brings in everything. The library is split into smaller modules if you'd rather start small or leave the operators out; see [Modules](#modules).

## Quick Start

A first taste: turn a raw string from a form into a greeting, where any step can fail. These are ordinary Swift functions returning `Result`.

```swift
import FP

enum SignUpError: Error, Sendable { case notANumber, underage, emptyName }

func parseAge(_ raw: String) -> Result<Int, SignUpError> {
    Int(raw).fold(onNone: .failure(.notANumber), onSome: Result.success)
}

func validateAdult(_ age: Int) -> Result<Int, SignUpError> {
    age >= 18 ? .success(age) : .failure(.underage)
}

func greet(_ age: Int) -> String { "Welcome! You are \(age)." }

func onboard(_ raw: String) -> Result<String, SignUpError> {
    parseAge(raw).flatMap(validateAdult).map(greet)
    // with operators: parseAge(raw) >>- validateAdult <&> greet
}

onboard("25")   // .success("Welcome! You are 25.")
onboard("12")   // .failure(.underage)
onboard("abc")  // .failure(.notANumber)
```

`fold` (added by FP to `Optional`) says what to do in each case, nothing and something, in one expression. `flatMap` runs the next step only if the previous one succeeded, and `map` transforms the final value. If something fails, the error travels to the end untouched.

`Result` stops at the first failure. For a form you usually want to report every problem at once, and that's what `Validation` (one of the types FP adds) is for:

```swift
func checkName(_ name: String) -> Validation<[SignUpError], String> {
    name.isEmpty ? .failure([.emptyName]) : .success(name)
}

func checkAge(_ age: Int) -> Validation<[SignUpError], Int> {
    age >= 18 ? .success(age) : .failure([.underage])
}

func signUp(name: String, age: Int) -> Validation<[SignUpError], Person> {
    Validation.zip(checkName(name), checkAge(age)).map(Person.init)
}

signUp(name: "Ana", age: 30)  // .success(Person(name: "Ana", age: 30))
signUp(name: "", age: 12)     // .failure([.emptyName, .underage])
```

That's the whole idea of the library: small functions, joined by a handful of well-known combinators (`map`, `flatMap`, `zip`, `fold`, …) that behave the same way on every type. The rest of this README introduces them one at a time.

<details>
<summary>Types shared by the examples below</summary>

Every `swift` block in this README compiles when the blocks are concatenated from top to bottom (illustrative fragments use `swift-sketch` fences). The examples share these small types:

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

// Errors used by the Result examples
enum AppError: Error, Sendable, Equatable { case notFound, offline, invalidInput }

// An error that can be combined with another one (a Monoid, see "Combining values")
struct Problems: Error, Monoid, Equatable {
    var messages: [String]
    static let identity = Problems(messages: [])
    static func combine(_ lhs: Problems, _ rhs: Problems) -> Problems { Problems(messages: lhs.messages + rhs.messages) }
}
```

</details>

## 1. More from the types you already use

Everything in this part works on Swift's own types (`Optional`, `Result`, `Array`, `Publisher`). Most of it builds on `map` and `flatMap`, which you probably use already.

### Handling a missing value (`fold`)

An optional value has two cases, so handling it means saying what to do in each. `fold` does that in one expression, and `withDefault` covers the common "use this if it's missing" case:

```swift
// fold: one answer for "nothing", one for "something"
Optional(5).fold(onNone: 0, onSome: { $0 * 2 })   // 10
(nil as Int?).fold(onNone: 0, onSome: { $0 * 2 }) // 0

// withDefault: a fallback when the value is absent (curried, so it can be passed to map)
withDefault(0)(Optional(42))   // 42
withDefault(0)(nil)            // 0
[Optional(1), nil].map(withDefault(0))   // [1, 0]

// toList: an Optional seen as a list of zero or one elements
Optional(42).toList   // [42]
(nil as Int?).toList  // []
```

Arrays get curried folds too, which you can store and pass around like any other function:

```swift
let total = Array.foldLeft(0, +)
total([1, 2, 3, 4])                   // 10, computed as (((0+1)+2)+3)+4
Array.foldRight(-, 0)([1, 2, 3])      // 2, computed as 1-(2-(3-0))
```

"Collapsing a structure into one value" is called *folding*, and types that support it are *Foldable*. You'll see `foldMap`, a fold that combines values with a Monoid, in [Combining values](#3-combining-values-semigroup-and-monoid).

### Transforming what's inside (`map`)

You already know `map` from Swift: it changes the value inside a container and leaves the container alone. An array stays an array of the same length, an optional stays empty if it was empty, a failure stays a failure.

```swift
[1, 2, 3].map { $0 * 2 }                         // [2, 4, 6]
Optional(5).map { $0 * 2 }                       // Optional(10)
Result<Int, any Error>.success(5).map { $0 * 2 } // .success(10)
// with operators: Optional(5) <&> { $0 * 2 }
```

FP gives the same `map` to every type it adds (`Either`, `Validation`, `Loading`, `Reader`, …), so once you know it on `Optional` you know it everywhere. A type with a lawful `map` is called a *Functor*.

There is also a static, curried `fmap`: it takes the function first and gives back a function that works on containers, ready to be stored or passed along.

```swift
let doubleAll = [Int].fmap { $0 * 2 }
doubleAll([1, 2, 3])                        // [2, 4, 6]
Optional<Int>.fmap { $0 * 2 }(Optional(5))  // Optional(10)
```

**Mapping both sides (`bimap`)**

`Result` has two sides: `map` changes the success and `mapError` the failure. `bimap` does both in one call:

```swift
struct HTTPError: Error, Sendable { let code: Int }

let response: Result<Int, HTTPError> = .failure(HTTPError(code: 404))

response.bimap(
    { $0 * 2 },                                          // success path (not reached here)
    { $0.code == 404 ? AppError.notFound : .offline }    // failure path
)
// .failure(AppError.notFound)

Result<Int, HTTPError>.success(21).bimap({ $0 * 2 }, { _ in AppError.offline })   // .success(42)
```

### Chaining steps that can fail (`flatMap`)

Sometimes the function you `map` with returns a container itself, and you end up with one inside another:

```swift
Optional("42").map { Int($0) }   // Optional<Optional<Int>>: nested, awkward
```

`flatMap` does the same, then flattens the result:

```swift
Optional("42").flatMap { Int($0) }   // Optional<Int>
Optional("xx").flatMap { Int($0) }   // nil
```

If you've used optional chaining (`user?.address?.city`), you've used this idea: each `?.` is a step that stops the chain at the first `nil`. Types with a lawful `flatMap` are called *Monads*. The shape is always the same (a function returning the container), but what it does depends on the container.

**Optional: stop at the first `nil`**

```swift
func findUser(id: Int) -> User? { id == 42 ? User(id: 42, name: "Ada") : nil }
func findAddress(user: User) -> Address? { Address(city: "London") }
func city(from address: Address) -> String? { address.city }

let userCity = findUser(id: 42)
    .flatMap(findAddress)
    .flatMap(city)
// String?: nil if any step failed
```

**Result: stop at the first failure, keep the error.** That's the Quick Start's `parseAge(raw).flatMap(validateAdult)`.

**Array: every combination.** Each step can produce several results, and `flatMap` collects them all:

```swift
[1, 2, 3].flatMap { [$0, $0 * 10] }   // [1, 10, 2, 20, 3, 30]
```

**Publisher: one request after another.** Step two can't start before step one has produced its value. FP's `concatMap` runs each inner publisher to completion, in order, without dropping values (Combine's own `flatMap` runs them concurrently instead):

```swift
func fetchUser(id: Int) -> AnyPublisher<User, Never> { Just(User(id: id, name: "Ada")).eraseToAnyPublisher() }
func fetchPermissions(for user: User) -> AnyPublisher<[String], Never> { Just(["read"]).eraseToAnyPublisher() }
func loadDashboard(permissions: [String]) -> AnyPublisher<String, Never> { Just("dashboard").eraseToAnyPublisher() }

let dashboard = fetchUser(id: 42).concatMap(fetchPermissions).concatMap(loadDashboard)
// with operators: fetchUser(id: 42) >>- fetchPermissions >>- loadDashboard
```

**Joining two steps into one.** `kleisli` glues two functions that each return a container into a single function of the same kind, the way you'd chain ordinary functions:

```swift
func parseInt(_ raw: String) -> Int? { Int(raw) }
func doubleIt(_ n: Int) -> Int? { .some(n * 2) }

let parseAndDouble = Optional.kleisli(parseInt, doubleIt)
parseAndDouble("21")   // Optional(42)
parseAndDouble("xx")   // nil
// with operators: parseInt >=> doubleIt
```

### Combining independent values (`zip`)

`flatMap` is for steps that depend on each other. When two values are independent (a name and an age, two settings), `zip` combines them into a pair, and you get the pair only if both are there:

```swift
Optional.zip(Optional(1), Optional(2))          // Optional((1, 2))
Optional.zip(Optional(1), Optional<Int>.none)   // nil: one missing means no pair
```

Swift's `Result` doesn't have `zip`; FP adds it:

```swift
Result.zip(Result<Int, AppError>.success(1), Result<Int, AppError>.success(2))   // .success((1, 2))
Result.zip(Result<Int, AppError>.success(1), Result<Int, AppError>.failure(.offline)) // .failure(.offline)
```

Follow it with `map` to build something from the pair, as the Quick Start did with `Validation.zip(...).map(Person.init)`. `Result.zip` stops at the first failure; `Validation.zip` collects all of them.

On `Array` (and `Publisher`), `zip` pairs elements by position, like the standard library's `zip`, and stops at the shorter one:

```swift
Array.zip([1, 2, 3], ["a", "b", "c"])   // [(1, "a"), (2, "b"), (3, "c")]
```

### All or nothing (`traverse` and `sequence`)

You have a list of strings and a parser that may fail. `map` gives you a list of optionals, `[Int?]`, but what you usually want is "all of them parsed, or nothing": `[Int]?`. `traverse` maps and flips the nesting in one step; `sequence` only flips, for when you already have the `[Int?]`.

```swift
// Array<Optional> → Optional<Array>
// All must be present; one nil collapses the whole result
[Optional(1), Optional(2), Optional(3)].sequence()   // Optional([1, 2, 3])
[Optional(1), nil, Optional(3)].sequence()           // nil

["1", "2", "3"].traverse { Int($0) }    // Optional([1, 2, 3])
["1", "x", "3"].traverse { Int($0) }   // nil

// Array<Result> → Result<Array>
[Result<Int, AppError>.success(1), .success(2)].sequence()           // .success([1, 2])
[Result<Int, AppError>.success(1), .failure(.notFound)].sequence()        // .failure(.notFound)

// Optional<Array> → Array<Optional>
Optional([1, 2, 3]).sequence()   // [Optional(1), Optional(2), Optional(3)]
(nil as [Int]?).sequence()       // [nil]

// Optional<Result> → Result<Optional>
Optional(Result<Int, AppError>.success(42)).sequence()   // .success(Optional(42))
(nil as Result<Int, AppError>?).sequence()               // .success(nil)
```

### Falling back to another value (`alt`)

`alt` tries the first value and, if it is "empty" (`nil`, a failure), falls back to the second. The second side is only evaluated when needed.

```swift
// Optional: the first non-nil wins
Optional.alt(nil, Optional(3))   // Optional(3)
Optional.alt(Optional(1), Optional(3))   // Optional(1)

// Result: the first success wins
Result.alt(Result<Int, AppError>.failure(.notFound), .success(3))   // .success(3)

// Array: both lists, one after the other
Array.alt([1, 2], [3, 4])   // [1, 2, 3, 4]
// with operators: cachedUser <|> fetchedUser
```

`Either` and `Validation` (next part) have `alt` too. On `Validation`, when both sides fail, both sets of errors are kept.

### Safe collection access

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

The id-mismatch guard protects against accidental swaps — assigning an element whose `id` doesn't match the subscript key is almost always a bug. Lookup is linear (`first(where:)` / `firstIndex(where:)`); for hot paths with large collections, reach for [`IdentifiedArray`](#identifiedarray-ordered-with-fast-lookup-by-id) (below), which keeps order *and* gives O(1) by-id access.

The setter requires `RangeReplaceableCollection` because the add/remove cases must change the collection's count — `MutableCollection` alone can only replace in place. `Array` and its slice variants cover the practical targets.

### Small helpers

**`Mutable`** — builder-pattern copy for value types

```swift
struct Endpoint: Mutable { var host: String; var port: Int }

let base = Endpoint(host: "localhost", port: 8080)
let dev  = base.mutate { $0.port = 3000 }     // Endpoint(host: "localhost", port: 3000)
let prod = base.mutate { $0.host = "prod.example.com" }
```

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
```

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

## 2. New types for your domain

Swift gives you `Optional` and `Result`. These types cover other situations that come up in almost every app. They live in the `DataStructure` module and all support the `map` / `flatMap` / `zip` you saw in part 1.

### Either: one thing or another

`Either<Left, Right>` holds one of two values. It looks like `Result`, but neither side has to be an error, so it fits any "this or that" in your model:

```swift
typealias UserRef = Either<Int, String>   // a numeric id or a username

let refs: [UserRef] = [.left(42), .right("ada")]
refs.map { $0.match(caseLeft: { "id \($0)" }, caseRight: { "@\($0)" }) }   // ["id 42", "@ada"]
```

By convention, `.right` is the "main" case: `map` and `flatMap` act on it, as they do on `Result`'s success. When the left side is an error, `toResult()` turns it into a `Result` (see [Converting between types](#converting-between-types)).

### Validation: collect every error

`Result` stops at the first failure. `Validation<E, A>` keeps going and combines the failures, which is what you want when checking a form: show every problem at once. `E` must be something that can be combined (usually an array of errors, see [Combining values](#3-combining-values-semigroup-and-monoid)).

You saw `zip` followed by `map` in the Quick Start. `liftA2` does both in one call:

```swift
let name: Validation<[String], String> = .failure(["name is empty"])
let age: Validation<[String], Int> = .failure(["age is negative"])

Validation<[String], Person>.liftA2({ Person(name: $0, age: $1) })(name, age)
// .failure(["name is empty", "age is negative"])

Validation(Either<[String], Int>.right(1))   // .success(1), converts from Either
```

Because `Validation` never stops early, it has no `flatMap` (a step that depends on the previous value would have to stop when that value is missing). Check independent things with `Validation`, and switch to `Result` or `Either` for steps that depend on each other.

### Loading: data that takes time

Screens that fetch data go through the same states again and again: nothing yet, loading, loaded, failed. `Loading<Success, Failure>` models exactly that (`idle` / `loading` / `loaded` / `failed`), and `loading` and `failed` can keep the previous value, so a refresh doesn't blank the screen. `Failure` can be any `Sendable` type (a `String`, a view struct), not only an `Error`. `loadedOrPrevious` keeps a view showing the last good value, `catch` receives `(Failure, Success?)`, and `pessimisticCombine` merges two loading states for a screen that needs both ("failed beats loading beats idle").

```swift
let state: Loading<[Item], String> = .failed(error: "offline", previous: [Item(id: 1, name: "A")])

state.loadedOrPrevious                                      // Optional([Item(id: 1, name: "A", views: 0)])
state.catch { _, previous in Loading<[Item], String>.loading(previous: previous) }  // retry, keep stale data
Loading<(Int, Int), String>.pessimisticCombine(Loading<Int, String>.loading(previous: nil), Loading<Int, String>.failed(error: "x", previous: nil))
// .failed(error: "x", previous: nil)
```

### Newtype: an `Int` that isn't just an `Int`

A user id and an order id may both be `Int`s, but passing one where the other is expected is a bug. `Newtype<Tag, RawValue>` wraps a value in its own type, told apart by a `Tag` that exists only for the compiler and costs nothing at runtime. Two `Newtype`s with different tags are entirely different types to the compiler — even when the underlying `RawValue` is identical — so mixing them up is a compile-time error, not a runtime bug.

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

### IdentifiedArray: ordered, with fast lookup by id

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

**First-class optics.** `IdentifiedArray` comes with its own optics, which compose like any other:

```swift
IdentifiedArrayOf<User>.ix(id: 2)            // O(1) AffineTraversal, zero-copy in-place mutation
IdentifiedArrayOf<User>.ix(id: 2).compose(lens(\User.name))
IdentifiedArrayOf<User>.traversed            // Traversal over every element
IdentifiedArrayOf<User>.arrayIso             // lawful Iso  <-> [Element]
IdentifiedArrayOf<User>.dedupPrism           // Prism [Element] -> IdentifiedArray (succeeds iff ids unique)
IdentifiedArrayOf<User>.orderedDictionaryIso // lawful Iso <-> (ids, lookup) — the *honest* keyed iso
```

The `.dictionary` getter projects to `[ID: Element]` but is explicitly **lossy** (drops order) — a getter, not an iso. The lawful keyed iso is `orderedDictionaryIso`, which pairs the lookup with the order it would otherwise lose.

**What it deliberately doesn't do.** `IdentifiedArray` is a `Semigroup` (`combine` appends, and a duplicate id keeps the last one), but it has no `map` or `flatMap`: a `map` that changed ids could merge elements and change the count, which would break the rules `map` promises everywhere else. To transform elements into something else, go through `.elements` (a plain array) and rebuild with `dedupPrism` (reports duplicate ids) or `arrayIso` (last one wins). Edits that keep the id stay on the type via `subscript(id:)`, `ix(id:)` and `traversed`.

### Converting between types

Related types convert with `to…()` going out and `init(_:)` coming in, so there is no guessing which direction a bridge goes:

```swift
let e: Either<Problems, Int> = .right(1)

e.toResult()                 // Result<Int, Problems>.success(1)  (the left side must be an `Error`)
e.toValidation()             // Validation<Problems, Int>.success(1)  (the left side must be combinable)
Validation(e).toEither()     // Either<Problems, Int>.right(1)
Loading<Int, AppError>(Result<Int, AppError>.success(1))   // .loaded(1)
```

`These(either)` and `Zipper(nonEmpty)` follow the same convention.

### All types

Each type in this library has a dedicated reference page with comprehensive examples covering every operation, operator, and transformer combination.

The links open the article sources in this repository; the same pages are rendered at [ios.lu/FP](https://ios.lu/FP).

#### CoreFP

| Type | Description |
|------|-------------|
| [Optional](Sources/CoreFP/CoreFP.docc/Optional.md) | Swift's built-in optional, extended with `fold`, `zip`, `alt`, `traverse` and more |
| [Array](Sources/CoreFP/CoreFP.docc/Array.md) | Swift's built-in array, extended with `traverse`, `cartesian`, curried folds and more |
| [Result](Sources/CoreFP/CoreFP.docc/Result.md) | Swift's built-in result, extended with `zip`, `bimap`, `alt`, `fold` and ways to combine results |
| [Publisher](Sources/CoreFP/CoreFP.docc/Publisher.md) | Combine's `AnyPublisher`, extended with ordered `concatMap`, `zip` and more _(Apple platforms only)_ |
| [AsyncSequence](Sources/CoreFP/CoreFP.docc/AsyncSequence.md) | Swift's `AsyncSequence`, extended with functional operations |
| [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) | SwiftUI's `Binding`, extended with `[optic:]` subscripts for `Lens`, `Iso`, `Prism`, and `AffineTraversal` _(Apple platforms only)_ |

#### DataStructure

| Type | Description |
|------|-------------|
| [Either](Sources/DataStructure/DataStructure.docc/Either.md) | One of two values, neither of which has to be an error |
| [Loading](Sources/DataStructure/DataStructure.docc/Loading.md) | Data that takes time: `idle` / `loading` / `loaded` / `failed`, keeping the last good value through a refresh or an error. `Failure` can be any `Sendable` type, not only `Error` |
| [Validation](Sources/DataStructure/DataStructure.docc/Validation.md) | Like `Result`, but collects every failure instead of stopping at the first |
| [Reader](Sources/DataStructure/DataStructure.docc/Reader.md) | A computation that needs dependencies, supplied later: wraps `(Environment) -> Output` |
| [Stateful](Sources/DataStructure/DataStructure.docc/Stateful.md) | A computation that reads and updates state: wraps `(inout S) -> A` |
| [Writer](Sources/DataStructure/DataStructure.docc/Writer.md) | A value together with a log that grows as steps run |
| [NonEmpty](Sources/DataStructure/DataStructure.docc/NonEmpty.md) | A collection guaranteed by the type to have at least one element, so `first` is never optional |
| [IdentifiedArray](Sources/DataStructure/DataStructure.docc/IdentifiedArray.md) | An ordered collection with O(1) lookup and update by id |
| [These](Sources/DataStructure/DataStructure.docc/These.md) | This, that, or both (for example a result plus warnings) |
| [Zipper](Sources/DataStructure/DataStructure.docc/Zipper.md) | A list with a current position you can move around in O(1) |
| [Gen](Sources/DataStructure/DataStructure.docc/Gen.md) | Random test data, generated from a random-number generator you provide |

## 3. Combining values (Semigroup and Monoid)

Adding numbers, concatenating strings and arrays, merging dictionaries: they're all "take two values, get one". FP gives this a common name, so the same functions (`combine`, `mconcat`) work on all of them, and on your own types.

### Joining two values (Semigroup)

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

With the operators module, `combine` is spelled `<>`: `"Hello, " <> "World!"`.

### A neutral starting point (Monoid)

A **Monoid** is a semigroup with one extra requirement: there must be a neutral element (called `identity`) that leaves any value unchanged when combined with it — regardless of which side it appears on.

```swift
String.combine("", "hello")  // "hello": the empty string is the identity for String
String.combine("hello", "")  // "hello"

Array.combine([], [1, 2])    // [1, 2]: the empty array is the identity for Array
Array.combine([1, 2], [])    // [1, 2]
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

`Optional<A>` is a `Semigroup` when `A` is a `Semigroup`, and a `Monoid` when `A` is a `Monoid`. Both present → combine the wrapped values; one nil → return the non-nil side; both nil → nil. The identity is `.none`.

```swift
let a: String? = "hello"
let b: String? = " world"

Optional<String>.combine(a, b)           // Optional("hello world") — both present: combine
Optional<String>.combine(a, .none)       // Optional("hello")       — only left present
Optional<String>.combine(.none, b)       // Optional(" world")      — only right present
Optional<String>.combine(.none, .none)   // nil
Optional<String>.identity                // nil

mconcat([a, .none, b])                   // Optional("hello world")
mconcat([.none, .none] as [String?])     // nil — identity
```

**Result**

There's more than one reasonable way to combine two `Result`s (should a success win over a failure, or the other way round?), so FP doesn't pick one for you. Four wrappers inside `Result.Monoids` let you say which one you mean. The examples use the `Problems` error from the shared types, which is itself a Monoid (its messages concatenate):

| Wrapper | Bias | When both sides match |
|---|---|---|
| `Optimistic` | success wins | only successes combine; two failures keep the left; `Failure` need not be `Semigroup` |
| `OptimisticCombining` | success wins | both sides combine; identity is `.failure(Failure.identity)` |
| `Pessimistic` | failure wins | only failures combine; two successes keep the left; `Success` need not be `Semigroup` |
| `PessimisticCombining` | failure wins | both sides combine; identity is `.success(Success.identity)` |

```swift
typealias R = Result<String, Problems>
let bad = Problems(messages: ["bad"])
let worse = Problems(messages: ["worse"])

// Optimistic: success wins; two failures keep the left
R.Monoids.Optimistic.combine(.init(.success("hello")), .init(.success(" world"))).rawValue  // .success("hello world")
R.Monoids.Optimistic.combine(.init(.success("hello")), .init(.failure(bad))).rawValue       // .success("hello")
R.Monoids.Optimistic.combine(.init(.failure(bad)), .init(.failure(worse))).rawValue         // .failure(bad)

// OptimisticCombining: success wins; matching sides combine
R.Monoids.OptimisticCombining.combine(.init(.failure(bad)), .init(.failure(worse))).rawValue  // .failure(["bad", "worse"])
R.Monoids.OptimisticCombining.identity.rawValue                                               // .failure([]): Failure.identity

// Pessimistic: failure wins; two successes keep the left
R.Monoids.Pessimistic.combine(.init(.failure(bad)), .init(.success("ok"))).rawValue    // .failure(bad)
R.Monoids.Pessimistic.combine(.init(.success("ok")), .init(.success("ok2"))).rawValue  // .success("ok")

// PessimisticCombining: failure wins; matching sides combine
R.Monoids.PessimisticCombining.combine(.init(.failure(bad)), .init(.failure(worse))).rawValue  // .failure(["bad", "worse"])
R.Monoids.PessimisticCombining.identity.rawValue                                               // .success(""): Success.identity

// mconcat works on the two Monoid variants
mconcat([
    R.Monoids.OptimisticCombining(.success("hello")),
    R.Monoids.OptimisticCombining(.failure(bad)),
    R.Monoids.OptimisticCombining(.success(" world")),
]).rawValue  // .success("hello world"): successes win and combine
```

An empty tray of lasagna would be the identity element — making lasagna a monoid too.

**Folding with a Monoid (`foldMap`)**

`foldMap` turns each element into a Monoid and combines them all, starting from the identity. An empty input simply gives the identity back:

```swift
[Int].foldMap { Int.Monoids.Sum($0) }([1, 2, 3])   // Sum(6)
Optional(3).foldMap { Int.Monoids.Sum($0) }        // Sum(3)
(nil as Int?).foldMap { Int.Monoids.Sum($0) }      // Sum(0): the identity
```

## 4. Updating nested data (optics)

Swift structs and enums are values, which is great until you need to change a field three levels deep. *Optics* are small values that point at one part of a bigger value, so you can read or update that part without unpacking everything around it. They compose: a path to `address`, then to `city`, is a path to the city.

### Structs: Lens

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

The real power is composition. `compose` chains two lenses into one that dives deeper into the structure:

```swift
let addressLens: Lens<Account, Address> = lens(\.address)
let cityLens: Lens<Address, String>     = lens(\.city)

let userCityLens = addressLens.compose(cityLens)  // Lens<Account, String>
// with operators: addressLens >>> cityLens

let user = Account(address: Address(city: "New York"), name: "Alice")
userCityLens.get(user)              // "New York"
userCityLens.set(user, "London")    // Account(address: Address(city: "London"), name: "Alice")
```

Lenses also compose with Prisms — see [Paths that may not exist](#paths-that-may-not-exist-affinetraversal) for the full story.

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

Composing any lens with it gives the same lens back, the way adding 0 leaves a number unchanged.

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

A `Binding<Root>` combined with a `Lens<Root, Focus>` produces a `Binding<Focus>`:

```swift-sketch
@State var user = Person(name: "Alice", age: 30)
let nameLens: Lens<Person, String> = lens(\.name)

TextField("Name", text: $user[optic: nameLens])
```

See [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) for the full bridge API.

### Enums: Prism

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

Prisms compose with other prisms and with lenses — see [Paths that may not exist](#paths-that-may-not-exist-affinetraversal) for the full story.

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

`Binding[optic: prism]` returns `Binding<A>?` — `nil` when the focused case is inactive:

```swift-sketch
@State var sheet: Sheet = .settings(Settings())

if let settingsBinding = $sheet[optic: settingsPrism] {
    SettingsView(settings: settingsBinding)
}
```

See [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) for the full bridge API.

### Paths that may not exist: AffineTraversal

Assembling an `AffineTraversal` is like aligning a lens and a prism in a telescope — each brings its own focus, and together they reach deeper into a structure than either could alone. The `AffineTraversal` is the optic you get whenever a focus *may or may not exist*, combining optional extraction with structural update.

It has three operations:
- `preview` — tries to extract the focused value; returns `nil` if the focus is absent
- `set` — updates the focused value if present; leaves the structure unchanged if absent
- `over` — applies a transform to the focused value if present

**A lens, then a prism**

Start with a struct and drill down to a field that is itself an enum case:

```swift
struct Canvas { var shape: Shape }

let shapeLens: Lens<Canvas, Shape>    = lens(\.shape)
let circlePrism: Prism<Shape, Double> = prism(
    preview: { if case .circle(let r) = $0 { return r } else { return nil } },
    review:  Shape.circle
)

// Lens, then Prism = AffineTraversal<Canvas, Double>
let circleRadiusTraversal = shapeLens.compose(circlePrism)

let canvas = Canvas(shape: .circle(5.0))
circleRadiusTraversal.preview(canvas)                      // Optional(5.0)
circleRadiusTraversal.set(canvas, 10.0)                    // Canvas(shape: .circle(10.0))
circleRadiusTraversal.over { $0 * 2 }(canvas)             // Canvas(shape: .circle(10.0))

let rectCanvas = Canvas(shape: .rectangle(3, 4))
circleRadiusTraversal.preview(rectCanvas)                  // nil
circleRadiusTraversal.set(rectCanvas, 10.0)               // Canvas(shape: .rectangle(3, 4)) — unchanged
```

**A prism, then a lens**

Go the other direction: start with an enum case and drill further into the associated value:

```swift
let loggedInPrism: Prism<App, Account> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review:  App.loggedIn
)
let cityLens: Lens<Account, String> = lens(\Account.address).compose(lens(\Address.city))

// Prism, then Lens = AffineTraversal<App, String>
let cityInLoggedInUser = loggedInPrism.compose(cityLens)

let paris = Account(address: Address(city: "Paris"), name: "Ann")
cityInLoggedInUser.preview(.loggedIn(paris))   // Optional("Paris")
cityInLoggedInUser.preview(.guest)             // nil
cityInLoggedInUser.set(.loggedIn(paris), "London")
// .loggedIn(Account(address: Address(city: "London"), name: "Ann"))
```

**Building a longer pipeline**

Because all three optic types compose with each other, you can chain freely:

```swift
let loggedInPrism: Prism<App, Account> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review:  App.loggedIn
)
let circlePrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)

let radiusTraversal = loggedInPrism.compose(lens(\Account.avatar)).compose(circlePrism)
// AffineTraversal<App, Double>
// with operators: loggedInPrism >>> ^\Account.avatar >>> circlePrism
```

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

`Binding[optic: affineTraversal]` returns `Binding<A>?` — `nil` when the focus is absent:

```swift-sketch
@State var app: App = .loggedIn(Account(address: Address(city: "Paris"), name: "Ann"))

if let cityBinding = $app[optic: loggedInPrism.compose(lens(\Account.address)).compose(lens(\Address.city))] {
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
let circleRadiusTraversal = lens(\Canvas.shape).compose(prism(\.circleRadius, review: Shape.circle))
let scaleRadius = EndoMut<Double> { $0 *= 2 }
let canvasReducer: EndoMut<Canvas> = circleRadiusTraversal.lift(scaleRadius)

var canvas = Canvas(shape: .circle(5.0))
canvasReducer(&canvas)   // Canvas(shape: .circle(10.0))
```

The copy cost depends on which optic sits at each link of the chain. See [Lifting `EndoMut` through optics](#lifting-endomut-through-optics) for the full breakdown.

### Collections: `ix`

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

Because `ix` returns an `AffineTraversal`, it composes with the other optics:

```swift
struct Team { var members: [Item] }

let items = [Item(id: 1, name: "A"), Item(id: 2, name: "B")]

// AffineTraversal<Team, String>
let memberNameFocus = lens(\Team.members).compose([Item].ix(id: 2)).compose(lens(\Item.name))

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

### Two-way conversions: Iso

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

Every `Iso` is also a valid `Lens`, `Prism`, and `AffineTraversal` — use `.asLens`, `.asPrism`, or `.asAffineTraversal` to downcast when needed. The identity iso `Iso<A, A>.id` is the strongest neutral element — see [Identity optics](#identity-optics-id).

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

**Composing an Iso with other optics.** `compose` returns the strongest optic the combination allows:

| Composition | Result |
|-------------|--------|
| Iso, then Iso | `Iso` |
| Iso with Lens (either order) | `Lens` |
| Iso with Prism (either order) | `Prism` |
| Iso with AffineTraversal (either order) | `AffineTraversal` |

```swift
let addOne = iso(get: { $0 + 1 }, reverseGet: { $0 - 1 })
let timesTwo = iso(get: { $0 * 2 }, reverseGet: { $0 / 2 })

let combined = addOne.compose(timesTwo)  // Iso<Int, Int>
combined.get(5)          // (5+1)*2 = 12
combined.reverseGet(12)  // 12/2 - 1 = 5
// with operators: addOne >>> timesTwo
```

**Bridging to SwiftUI `Binding`** _(Apple platforms, requires CoreFP)_

`Binding[optic: iso]` always returns a `Binding<A>` (never optional — Iso is total):

```swift-sketch
@State var meters: Double = 1.0

// Editing in feet while storing in meters:
TextField("Feet", value: $meters[optic: metersToFeet], format: .number)
```

See [Binding](Sources/CoreFP/CoreFP.docc/Binding.md) for the full bridge API.

### Identity optics (`.id`)

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

### Chaining transformations (Endo)

`Endo<A>` wraps an endomorphism — a function `(A) -> A` — and gives it a `Monoid` instance under left-to-right composition. The identity element is the do-nothing function.

```swift
let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
let lower   = Endo<String> { $0.lowercased() }
let exclaim = Endo<String> { $0 + "!" }

let normalize: Endo<String> = mconcat([trim, lower, exclaim])
normalize.runEndo("  HELLO  ")   // "hello!"
normalize("  HELLO  ")           // "hello!" — callAsFunction works too
```

`Endo.combine(f, g)` applies `f` first, then `g`, and `mconcat` runs a whole list in order:

```swift
let pipeline = Endo.combine(Endo<String> { $0.lowercased() }, Endo<String> { $0 + "!" })
pipeline("HELLO")   // "hello!"
// with operators: lower <> exclaim
```

**`Endo` vs `Iso<A, A>`**

Both are endomorphisms and both form a `Monoid` under composition, but they differ in one key way:

| | `Endo<A>` | `Iso<A, A>` |
|---|---|---|
| Stores | `(A) -> A` | `(A) -> A` + inverse `(A) -> A` |
| Reversible | no | yes — `.reverse` gives the undo |
| Use when | trimming, clamping, normalizing | rotating, scaling, unit conversion |

You can always extract an `Endo` from an `Iso<A, A>` via `.get`, but not vice versa — invertibility requires both directions up front.

### Updating in place without copies (EndoMut)

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

`EndoMut.combine(f, g)` applies `f` first, then `g`, and `g` sees every mutation `f` made:

```swift
let clampAll = EndoMut<[Int]> { xs in for i in xs.indices { xs[i] = min(xs[i], 100) } }
let sortAll = EndoMut<[Int]> { $0.sort() }
var numbers = Array(0..<10_000)

EndoMut.combine(clampAll, sortAll)(&numbers)   // same as mconcat([clampAll, sortAll])
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

### Generating optics (and more) with macros

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

For the library's own generic `Newtype`, prefer its built-in `Newtype.iso` (see [Newtype](#newtype-an-int-that-isnt-just-an-int)) rather than applying this macro.

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

A bare `Int` field won't work — `Int` has no single canonical monoid; wrap it as `Int.Monoids.Sum` / `Int.Monoids.Product` first (see [Monoid](#a-neutral-starting-point-monoid)). The struct must keep its memberwise initialiser (synthesised or written).

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

## 5. Effects as values

Reading configuration, keeping a counter, writing a log: these are usually hidden inside functions as globals or captured variables. The types in this part make them visible in the function's type instead, so the function stays easy to test and reason about.

### Dependencies: Reader

`Reader<Environment, Output>` is a function waiting for its dependencies. You describe what to compute assuming the environment is there, and supply the real one later, at the edge of your program (or a fake one in a test). Nothing runs until you call `runReader`.

```swift
struct Settings: Sendable { var language: String }

let hello = Reader<Settings, String> { $0.language == "pt" ? "Olá" : "Hello" }
let welcome = hello.map { "\($0), welcome!" }

welcome.runReader(Settings(language: "pt"))   // "Olá, welcome!"
welcome.runReader(Settings(language: "en"))   // "Hello, welcome!"
```

`map` and `flatMap` work as before, and every step sees the same environment without you passing it around by hand.

**Needing less than the whole environment (`contramapEnvironment`)**

A piece of code that only needs one dependency shouldn't have to know about all of them. Write it against the small part, then adapt it to the full environment with a key path:

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

`map` changes what comes out; `contramapEnvironment` changes what goes in (the name comes from *contravariance*, mapping in the opposite direction). `dimap` does both in one call:

```swift
// A reader scoped to just the URLRequester
let checkReachability: Reader<URLRequester, Bool> = Reader { $0.isReachable }

// Narrow the input from Dependencies to URLRequester, and describe the Bool result as a String
let serviceStatus: Reader<Dependencies, String> = checkReachability.dimap(
    \.urlRequester,                               // Dependencies → URLRequester (narrow the environment)
    { $0 ? "service online" : "service offline" } // Bool → String (describe the result)
)
```

### State: Stateful

`Stateful<S, A>` is a computation that reads and updates a piece of state while producing a value. Instead of a `var` shared between functions, the state is passed explicitly from one step to the next, so you can run the same computation from any starting state (and test it that way).

```swift
let nextTicket = Stateful<Int, String> { counter in
    counter += 1
    return "Ticket #\(counter)"
}

let twoTickets = nextTicket.flatMap { first in nextTicket.map { second in [first, second] } }
twoTickets.runStateful(0)    // (["Ticket #1", "Ticket #2"], 2)
twoTickets.runStateful(10)   // (["Ticket #11", "Ticket #12"], 12)
```

It's called `Stateful` rather than `State` so it doesn't clash with SwiftUI's `@State`.

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

### Logs: Writer

`Writer<Log, A>` produces a value together with a log. Each step adds to the log, and `flatMap` joins the logs for you (any Monoid works as a log: an array of messages, a sum, …):

```swift
func halve(_ n: Int) -> Writer<[String], Int> { Writer(n / 2, ["halved \(n)"]) }

let halvedTwice = halve(40).flatMap(halve)
halvedTwice.value   // 10
halvedTwice.log     // ["halved 40", "halved 20"]
```

**Looking at the whole context (`extend`)**

`flatMap` hands each step only the value. `coflatMap` (also called `extend`) hands it the whole `Writer`, log included, and `extract` reads the value back out. Types with these operations are called *Comonads*; `NonEmpty`, `Zipper` and `Reader` (when its environment is a Monoid) have them too.

```swift
// extract — pull out the value (dual of pure)
Writer(42, ["log"]).extract   // 42

// coflatMap / extend — map a function over the entire writer context
Writer(21, ["step"]).coflatMap { w in w.value * 2 + w.log.count }
// Writer(43, ["step"])   — value: 21*2 + 1, log preserved

// duplicate — wrap the writer in another writer (dual of join)
Writer(42, ["log"]).duplicate   // Writer(Writer(42, ["log"]), ["log"])
```

### Random test data: Gen

Property-based tests check a rule against hundreds of random inputs instead of a few hand-picked ones. `Gen<R, Value>` describes how to build such random values. It's a `Stateful` computation whose state is the random-number generator:

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

### Combining effects (transformer stacks)

You'll eventually combine two of these: a `Reader` whose result is a list, a `Stateful` step that can fail. A `Reader<Config, [User]>` is a Reader, so `map` on it sees the whole array. When you want to work
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
let checked = current.statefulT.flatMap(refreshIfExpired)   // StatefulTEither<Session, AuthError, Token>
// with operators: current.statefulT >>- refreshIfExpired
```

Lift with the property named after the outer type (`readerT`, `statefulT`, `writerT`, `publisherT`,
`asyncStreamT`, `arrayT`, `optionalT`, `resultT`, `eitherT`, `validationT`, `nonEmptyT`) or the
initialiser, leave with `.rawValue`, and for anything the stack doesn't proxy use the
escape hatch (`mapReaderT`, `mapStateT`, `mapPublisherT`, `mapMaybeT`, `mapExceptT`, `mapWriterT`, …),
which hands you the whole nested value (for example `stack.mapPublisherT { $0.receive(on: queue).eraseToAnyPublisher() }`).
Not every combination has a lawful `flatMap` (for example, any stack involving `Validation` stops at `zip`/`apply`). The full matrix, and the reasons, are in the [Monad Transformers](Sources/FP/FP.docc/Articles/MonadTransformers.md) article.

## 6. Building functions from functions

So far you've passed functions to `map` and `flatMap`. FP also has helpers for making new functions out of existing ones, so you can name a step once and reuse it instead of writing a closure each time.

### Composing and adapting functions

**Composition: `compose`**

`compose(f, g)` builds a new function that runs `f`, then `g`. Small named steps become a pipeline you can store, pass to `map`, and test on its own:

```swift
func trim(_ s: String) -> String { s.trimmingCharacters(in: .whitespaces) }
func uppercased(_ s: String) -> String { s.uppercased() }
func exclaim(_ s: String) -> String { s + "!" }

let shout = compose(compose(trim, uppercased), exclaim)
shout("  hello  ")              // "HELLO!"
["  hi ", "yo"].map(shout)      // ["HI!", "YO!"]
// with operators: trim >>> uppercased >>> exclaim
```

Key paths become functions with `get(_:)`, so they compose too:

```swift
struct Company { var ceo: Person }

let ceoName = compose(get(\Company.ceo), get(\Person.name))
[Company(ceo: Person(name: "Ada", age: 36))].map(ceoName)   // ["Ada"]
```

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
[1, 2].map(const(Result<Void, AppError>.success(())))   // all successes, structure preserved
```

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

**`withArg`** — select which argument to operate on in a multi-argument context

`withArg` takes a key path that picks one value from a tuple of arguments, then lets you plug a single-argument function into that position. This is useful when adapting a unary function into a binary or ternary context without a closure:

```swift
// Adapting a (String) -> Bool into (Int, String) -> Bool
// by selecting the second argument:
let isLongName: (Int, String) -> Bool = withArg(\.1)(compose(get(\String.count), { $0 > 5 }))
isLongName(42, "Alexander")   // true
isLongName(42, "Ali")         // false

// Selecting the first argument explicitly:
let doubleFirst: (Int, String) -> Int = withArg(\.0)({ $0 * 2 })
doubleFirst(21, "ignored")    // 42
```

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

A frequent use is narrowing a big value into a smaller one whose `init` takes the parts as separate
arguments — e.g. a feature's `Environment` from a `World`. Because Swift (SE-0110) treats a tuple argument
and a multi-argument parameter list as distinct types, there are two point-free spellings:

```swift
struct World: Sendable { var badge: Int; var save: Int }
struct Env: Sendable { let badge: Int; let save: Int }

// One call: `fanout(keypaths:into:)` (key paths are constrained to `Sendable`)
let a: @Sendable (World) -> Env = fanout(keypaths: \.badge, \.save, into: Env.init)

// Or compose the fanout with the multi-argument init
let b: @Sendable (World) -> Env = compose(fanout(\.badge, \.save), Env.init)
// with operators: fanout(\.badge, \.save) >>> Env.init
```

**`join` and `void`**

`join` flattens one layer of nesting; `void` discards the contained values while keeping the container shape:

```swift
// join — one layer in, same container out
join([[1, 2], [3, 4]])                                    // [1, 2, 3, 4]
join(Optional(Optional(42)))                              // Optional(42)
join(Result<Result<Int, AppError>, AppError>.success(.success(42)))     // .success(42)

// void — like map(ignore); keeps structure, discards values
void([1, 2, 3])          // [(), (), ()]
void(Optional(42))       // Optional(())
void(Result<Int, AppError>.success(99))   // .success(())
```

`void` differs from `ignore`: `ignore` is `(A) -> Void` (discards a single value entirely), while `void` is `Container<A> -> Container<Void>` (maps every element to `()`). Use `ignore` when you want to drop a value; use `void` when you want to strip the values from a container but keep its structure.

**Tuple utilities**

```swift
mapTuple2(uppercased)("hello", "world")    // ("HELLO", "WORLD")
mapTuple3({ $0 * 2 })(1, 2, 3)           // (2, 4, 6)
tuple(1, "hello")                          // (1, "hello")
untuple { (pair: (Int, Int)) in pair.0 + pair.1 }(3, 4)   // 7 (one tuple argument becomes two separate arguments)
```

**`lazy` / `unlazy`** — defer and force evaluation

```swift
func expensiveComputation() -> Int { 42 }
let later: @Sendable () -> Int = lazy(expensiveComputation())   // not evaluated yet
unlazy(later)                                          // forces it
```

**Boolean predicates** — curried, composable, for fully tacit style

`equals`, `notEquals`, `not`, `and`, `or` are overloaded for both `Bool` values and `(A) -> Bool` predicates, so they combine with key paths and `compose` to build predicates without writing closures:

```swift
struct Employee { let name: String; let age: Int; let isAdmin: Bool }
let users = [Employee(name: "Alice", age: 30, isAdmin: true), Employee(name: "Bob", age: 17, isAdmin: false)]

let isAlice = compose(get(\Employee.name), equals("Alice"))

users.filter(isAlice)                     // only "Alice"
users.filter(not(isAlice))                // everyone else
users.filter(not(\.isAdmin))              // non-admins only
users.filter(and(isAlice, \.isAdmin))     // Alices who are also admins
users.filter(or(isAlice, compose(get(\Employee.name), equals("Bob"))))   // Alices or Bobs
// with operators: users.filter(equals("Alice") <<< \.name)
```

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

### Functions inside containers (`apply`)

Apply is a related operation: what if the *function itself* is inside a container? `apply` unwraps both the function and the value, applies the function, and wraps the result back up:

```swift
Optional<Int>.apply({ $0 * 2 }, Optional(3))   // Optional(6)
Optional<Int>.apply(nil, Optional(3))          // nil
```

For `Array`, apply gives every combination — each function applied to every value:

```swift
[Int].apply([{ $0 + 1 }, { $0 * 10 }], [1, 2])  // [2, 3, 10, 20]
```

`Publisher` and `AsyncStream` work like `Array` here: every function runs over every value, in order. To pair values by position, use `zip` instead.

`apply` (and its cousins `liftA2`, `seqRight`, `seqLeft`) runs left to right and stops at the first failure, like `flatMap` does. The difference is that the second side can't depend on the first side's value. Types that support it are called *Applicatives*; `Validation` is one that is not also a Monad, which is why it can keep collecting errors instead of stopping.

If you want both sides of a `Publisher` or `AsyncStream` to run at the same time, use `zip`: it's the only one that subscribes to both concurrently.

## 7. Operators (optional)

Every operator in FP is a shorter spelling of a named function you've already met. They are opt-in (`CoreFPOperators` and `DataStructureOperators`, both included in `FP`), and nothing in the library requires them. Some people find `parseAge(raw) >>- validateAdult <&> greet` easier to read than the chain of method calls; if you don't, skip this part.

> Before adding the operator modules to an existing project, check for symbols you already define. Some (like `<>`, `>>>`, `|>`, or prefix `^`) also appear in other libraries and can cause ambiguity errors.

### Joining: `<>`

`<>` is `combine`:

`<>` is the infix operator for `combine`:

```swift
"Hello, " <> "World!"     // "Hello, World!"
[1, 2] <> [3, 4]          // [1, 2, 3, 4]
```

```swift
let trimEndo = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
let lowerEndo = Endo<String> { $0.lowercased() }
(trimEndo <> lowerEndo)("  HeLLo ")   // "hello"
```

### Mapping: `<£>`, `<&>`, `£>`, `<£`

Symbolic operators are syntactic sugar — every one of them delegates to a named function in `CoreFP`. Use them when they make the code more readable, ignore them when they don't.

`<£>` maps a function over a container (function on the left):

```swift
{ $0 * 2 } <£> Optional(5)                         // Optional(10)
{ $0 * 2 } <£> [1, 2, 3]                           // [2, 4, 6]
{ $0 * 2 } <£> Result<Int, AppError>.success(5)       // .success(10)
{ $0 * 3 } <£> Just(2).eraseToAnyPublisher()        // publisher of 6
```

`<&>` is the flipped version — container on the left:

```swift
Optional(5) <&> { $0 * 2 }                         // Optional(10)
[1, 2, 3] <&> { $0 * 2 }                           // [2, 4, 6]
Result<Int, AppError>.success(5) <&> { $0 * 2 }      // .success(10)
Just(2).eraseToAnyPublisher() <&> { $0 * 3 }       // publisher of 6
```

`£>` replaces the contents with a constant (container on the left, value on the right):

```swift
Optional(5) £> "hello"                              // Optional("hello")
[1, 2, 3] £> "x"                                   // ["x", "x", "x"]
Result<Int, AppError>.success(42) £> "done"           // .success("done")
Just(2).eraseToAnyPublisher() £> "done"             // publisher of "done"
```

`<£` is the flipped version — value on the left:

```swift
"hello" <£ Optional(5)                              // Optional("hello")
"x" <£ [1, 2, 3]                                   // ["x", "x", "x"]
"done" <£ Result<Int, AppError>.success(42)           // .success("done")
"done" <£ Just(2).eraseToAnyPublisher()             // publisher of "done"
```

### Chaining: `>>-`, `-<<`, `>=>`, `<=<`

`>>-` is bind with the container on the left — same argument order as `flatMap`:

```swift
Optional("42") >>- { Int($0) }                          // Optional(42)
[1, 2] >>- { [$0, $0 * 10] }                            // [1, 10, 2, 20]
Result<String, AppError>.success("2") >>- { Result<Int, AppError>.success(Int($0) ?? 0) } // .success(2)
Just(42).eraseToAnyPublisher() >>- { Just($0 * 2).eraseToAnyPublisher() }
```

`-<<` is the flipped version — function on the left, container on the right:

```swift
{ Int($0) } -<< Optional("42")   // Optional(42)
```

`>=>` composes two "Kleisli arrows" — functions that return containers — into one:

```swift
// parseInt and doubleIt from "Chaining steps that can fail"
let parseAndDoubleOp = parseInt >=> doubleIt
parseAndDoubleOp("21")   // Optional(42)
parseAndDoubleOp("xx")   // nil
```

This is function composition for container-returning functions. `<<<` and `>>>` compose regular functions; `>=>` and `<=<` compose Kleisli arrows.

`<=<` is the right-to-left version:

```swift
let parseAndDouble2 = doubleIt <=< parseInt
```

### Applying wrapped functions: `<*>`, `*>`, `<*`

`<*>` applies a wrapped function to a wrapped value (function container on the left):

```swift
let plus41: @Sendable (Int) -> Int = { $0 + 41 }
let double: @Sendable (Int) -> Int = { $0 * 2 }
let triple: @Sendable (Int) -> Int = { $0 * 3 }

Optional(plus41) <*> Optional(1)                                                 // Optional(42)
[double, triple] <*> [1, 2]                                                      // [2, 4, 3, 6]
Result<@Sendable (Int) -> Int, AppError>.success(double) <*> Result<Int, AppError>.success(21)   // .success(42)
Just(plus41).eraseToAnyPublisher() <*> Just(41).eraseToAnyPublisher()
```

`*>` sequences two effects and keeps the *right* result — the left effect still runs, but its value is discarded:

```swift
Optional(42) *> Optional("hello")   // Optional("hello") — 42 ran, but only "hello" survives
[1, 2] *> ["a", "b"]               // ["a", "b", "a", "b"]
Result<Int, AppError>.success(42) *> Result<String, AppError>.success("hello")  // .success("hello")
```

`<*` keeps the *left* result instead:

```swift
Optional("hello") <* Optional(42)               // Optional("hello")
["a", "b"] <* [1, 2]                            // ["a", "a", "b", "b"]
Result<String, AppError>.success("hello") <* Result<Int, AppError>.success(42)   // .success("hello")
```

### Choosing: `<|>`

`<|>` is `alt`:

```swift
// Optional — first non-nil wins
(nil as Int?) <|> Optional(3)   // Optional(3)
Optional(1)   <|> Optional(3)   // Optional(1) — first wins if present

// Array — concatenation
[1, 2] <|> [3, 4]   // [1, 2, 3, 4]
[]     <|> [3, 4]   // [3, 4]

// Result — first success wins
Result<Int, AppError>.failure(.notFound) <|> .success(3)   // .success(3)
Result<Int, AppError>.success(1)     <|> .success(3)   // .success(1)

// Either: first right wins
Either<String, Int>.left("no") <|> .right(3)   // .right(3)

// Validation is `Alt` (there is no `empty`): when both fail, the failures accumulate with `<>`
Validation<[String], Int>.failure(["a"]) <|> .failure(["b"])   // .failure(["a", "b"])
Validation<[String], Int>.failure(["a"]) <|> .success(3)       // .success(3)
```

### Composing functions and optics: `>>>`, `<<<`, `^`

`>>>` is `compose` (left to right) and `<<<` is the same thing right to left. They work on functions and on every optic:

```swift
let shoutOp = trim >>> uppercased >>> exclaim
let shoutOp2 = exclaim <<< uppercased <<< trim   // equivalent
shoutOp("  hello  ")   // "HELLO!"
```

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

### Applying a function: `<|`, `|>`

**Function application** — `<|` and `|>`

`<|` applies a function to a value with the function on the left. Its precedence group is lower than every other operator, so it eliminates wrapping parentheses. It is right-associative, so chains nest naturally:

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

### Extending: `->>`, `<<-`

`->>` extends a comonad (container on the left):

```swift
Writer(21, ["x"]) ->> { $0.value * 2 }   // Writer(42, ["x"])
```

`<<-` is the flipped version — function on the left:

```swift
{ $0.value * 2 } <<- Writer(21, ["x"])   // Writer(42, ["x"])
```

### Ranges: `±`, `≅`

`±` (or `+/-`) builds a closed range around a value, and `≅` checks membership with the value first:

```swift
41.within(42 ± 2)   // true: 41 falls inside 40...44
5 ≅ 1...10          // true, same as (1...10) ~= 5
```

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
| 9.5 | `>>>` | right | `FunctionCompositionForward` |
| 9 | `<<<` | right | `FunctionCompositionBackwards` |
| 8.5 | `>>` _(stdlib)_ | left | `BitwiseShiftPrecedence` |
| 7 | `*`, `/` _(stdlib)_ | left | `MultiplicationPrecedence` |
| 6.5 | `<>` | right | `ConcatPrecedence` (strictly between multiplication and addition) |
| 6 | `+`, `-` _(stdlib)_ | left | `AdditionPrecedence` |
| 4.8 | `...`, `..<` _(stdlib)_, `±` / `+/-` | none | `RangeFormationPrecedence` |
| 4.5 | `as?` _(stdlib)_ | none | `CastingPrecedence` |
| 4.2 | `??` _(stdlib)_ | right | `NilCoalescingPrecedence` |
| 4 | `==`, `<=` _(stdlib)_, `≅` | none | `ComparisonPrecedence` |
| below `??`, above `&&` | `<£>`, `£>`, `<£`, `<*>`, `*>`, `<*` | left | `FunctorOps` (no declared relation to the comparison operators: parenthesise when mixing with `==`) |
| 3 | `&&` _(stdlib)_ | left | `LogicalConjunctionPrecedence` |
| 2 | `\|\|` _(stdlib)_ | left | `LogicalDisjunctionPrecedence` |
| 1.5 | `<\|>` | left | `AlternativePrecedence` |
| 1.1 | `>=>`, `<=<`, `-<<`, `<<-` | right | `KleisliCompositionRight` |
| 1 | `>>-`, `<&>`, `->>` | left | `MonadBindLeft` |
| 0.5 | `?:` _(stdlib)_ | right | `TernaryPrecedence` |
| 0 | `<\|` | right | `LowPrecedenceFunctionCallRight` |
| 0 | `\|>` | left | `LowPrecedenceFunctionCallLeft` |
| -1 | `=` _(stdlib)_ | right | `AssignmentPrecedence` |

Practical takeaways:
- Following Haskell's fixities, the stdlib operators `*`, `+`, `??`, `==`, `&&` and `||` all bind tighter than `<\|>`, which binds tighter than `>=>` / `>>-`, which bind tighter than `<\|` and `\|>`. So `a <\|> b ?? c` is `a <\|> (b ?? c)` and `x == y \|> f` is `(x == y) \|> f`. The one deliberate gap is the functor family (`<£>`, `<*>`, …) against `==`: Haskell has them at the same level and rejects the mix, so parenthesise.
- `>>>` / `<<<` bind tighter than everything else, so composed functions and optics never need parentheses next to arithmetic or comparisons.
- `<|` / `|>` sit near the very bottom (just above assignment), which is what lets them wrap an entire expression without parentheses — `f <| a + b * c` parses as `f <| (a + b * c)`.
- `>=>` / `<=<` / `-<<` / `<<-` (`KleisliCompositionRight`, right-associative) bind slightly tighter than `>>-` / `<&>` / `->>` (`MonadBindLeft`, left-associative). Haskell puts both at level 1 (`infixr 1` / `infixl 1`), where mixing them without parentheses is an error; Swift needs two ordered groups, so `x >>- f >=> g` means `x >>- (f >=> g)`.

## Reference

### Modules

FP is split into modules so you can import only what you need. Each builds on the previous one.

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

### Concurrency: Sendable-first

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

### SumType2: one interface for two-case types

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
Result<Int, AppError>.failure(.notFound).isB   // true (failure maps to the right/B case)

// from — convert between any two conforming types with the same type parameters
let r = Result<Int, AppError>.from(Either<Int, AppError>.left(42))  // .success(42)
```

The protocol has three requirements, `left(_:)`, `right(_:)` and `match(caseLeft:caseRight:)`; `from(_:)`, `.a`, `.b`, `.isA` and `.isB` come for free as extensions. Use `SumType2` in your own generic functions to work over `Either`, `Result`, and any custom two-case type simultaneously.

Note that the mapping is positional: `Result`'s `A` is `Success`, while `Either`'s success-by-convention side is `.right` (`B`), so `Result.from(Either.right(x))` is `.failure(x)`.

### Coming from Haskell

If you know Haskell, the [Coming from Haskell](Sources/FP/FP.docc/Articles/ComingFromHaskell.md) article maps its types and operators to this library and explains which semantics FP follows.

## Learning more

New to functional programming? These are some of the best starting points:

- [Functors, Applicatives, and Monads in Pictures](https://mokacoding.com/blog/functor-applicative-monads-in-pictures/) — a visual, intuition-first introduction to the core concepts
- [Learn You a Haskell for Great Good!](https://learnyouahaskell.github.io/) — a beginner-friendly free book that explains the ideas behind this library

For a hands-on, interactive walkthrough, see the "Modeling Failures" tutorial and the full article catalog at **[ios.lu/FP](https://ios.lu/FP)**, which includes a runnable example for every type and function.

Using Claude Code (or another AI assistant) with this library? [`docs/claude-skills`](docs/claude-skills/README.md) has task-oriented prompt templates for both using the library (operators, Reader, Prisms, refactoring imperative code) and extending it (adding a new type, building a transformer stack).

Browse the complete API documentation with examples and tutorials for every type and function in FP, CoreFP, DataStructure, and all operator modules.

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

