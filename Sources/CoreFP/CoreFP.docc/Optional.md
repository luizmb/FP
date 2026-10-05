# ``Swift/Optional``

Swift's `Optional` extended with functional operators and named functions.

An `Optional<A>` is either `.some(value)` or `.none`. The operators let you transform, combine, and chain optional values without manual unwrapping.

---

## `<£>` and `<&>` — Map

Apply a function to the wrapped value. `<£>` puts the function on the left; `<&>` puts the optional on the left.

```swift
let m1 = { $0 * 2 } <£> Optional(5)      // Optional(10)
let m2 = { $0 * 2 } <£> (nil as Int?)    // nil

let m3 = Optional(5) <&> { $0 * 2 }      // Optional(10)
let m4 = (nil as Int?) <&> { $0 * 2 }    // nil

// Named function
let m5 = Optional.fmap { $0 * 2 }(Optional(5))  // Optional(10)
let m6 = Optional(5).map { $0 * 2 }             // Optional(10)
```

---

## `£>` and `<£` — Replace

Replace the wrapped value with a constant, keeping the `nil`/non-`nil` structure.

```swift
let c1 = Optional(42) £> "hello"   // Optional("hello")
let c2 = (nil as Int?) £> "hello"  // nil

let c3 = "hello" <£ Optional(42)   // Optional("hello")
let c4 = "hello" <£ (nil as Int?)  // nil

// Named function (fmap with const)
let c5 = Optional.fmap(const("hello"))(Optional(42))  // Optional("hello")
```

---

## `<*>` — Apply

Apply a function that is itself optional to an optional value. Both must be non-`nil`.

```swift
let double: @Sendable (Int) -> Int = { $0 * 2 }
let noFunction: (@Sendable (Int) -> Int)? = nil

let a1 = Optional(double) <*> Optional(5)      // Optional(10)
let a2 = Optional(double) <*> (nil as Int?)    // nil
let a3 = noFunction <*> Optional(5)            // nil

// Named function
let a4 = Optional.apply(Optional(double), Optional(5))  // Optional(10)
```

---

## `*>` and `<*` — Sequence

Run two optionals in sequence, keeping only one side's value. If either is `nil`, the result is `nil`.

```swift
let s1 = Optional("a") *> Optional("b")        // Optional("b")
let s2 = (nil as String?) *> Optional("b")     // nil
let s3 = Optional("a") *> (nil as String?)     // nil

let s4 = Optional("a") <* Optional("b")        // Optional("a")
let s5 = Optional("a") <* (nil as String?)     // nil

// Named functions
let s6 = Optional("a").seqRight(Optional("b")) // Optional("b")
let s7 = Optional("a").seqLeft(Optional("b"))  // Optional("a")
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain operations that each may return `nil`. `>>-` puts the container on the left; `-<<` puts the function on the left.

```swift
let parseInt: @Sendable (String) -> Int? = { Int($0) }
let doubleIfPositive: @Sendable (Int) -> Int? = { $0 > 0 ? .some($0 * 2) : nil }

let b1 = Optional("42") >>- parseInt                   // Optional(42)
let b2 = Optional("??") >>- parseInt                   // nil
let b3 = Optional(42) >>- doubleIfPositive             // Optional(84)
let b4 = Optional(-1) >>- doubleIfPositive             // nil

// Chained
let b5 = Optional("42") >>- parseInt >>- doubleIfPositive  // Optional(84)

let b6 = parseInt -<< Optional("42")   // Optional(42)
let b7 = parseInt -<< Optional("??")   // nil

// Named function
let b8 = Optional.bind(parseInt)(Optional("42"))  // Optional(42)
let b9 = Optional("42").flatMap { Int($0) }       // Optional(42)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return an `Optional`, producing a single function.

```swift
let toPositive: @Sendable (Int) -> Int? = { $0 > 0 ? $0 : nil }
let doublePositive: @Sendable (Int) -> Int? = { $0 > 0 ? $0 * 2 : nil }

let parsePositive = parseInt >=> toPositive
let k1 = parsePositive("42")   // Optional(42)
let k2 = parsePositive("-1")   // nil
let k3 = parsePositive("??")   // nil

// Three-way composition
let kleisliPipeline = parseInt >=> toPositive >=> doublePositive
let k4 = kleisliPipeline("21")   // Optional(42)
let k5 = kleisliPipeline("-1")   // nil

// Named function
let k6 = Optional.kleisli(parseInt, toPositive)("42")  // Optional(42)
```

---

## `<|>` — Alternative

Return the first non-`nil` value.

```swift
let alt1 = (nil as Int?) <|> Optional(3)    // Optional(3)
let alt2 = Optional(1) <|> Optional(3)     // Optional(1)
let alt3 = (nil as Int?) <|> (nil as Int?) // nil
```

---

## Fold (Foldable)

### `withDefault` — provide a fallback

`withDefault` is a curried function for point-free composition. It replaces `nil` with a fallback value:

```swift
let w1 = withDefault(0)(Optional(42))   // 42
let w2 = withDefault(0)(nil)            // 0

// Curried version, useful in pipelines
let safeAge: @Sendable (String) -> Int = parseInt >>> withDefault(0)
let w3 = safeAge("25")   // 25
let w4 = safeAge("??")   // 0

// Two-argument version, provides a chain of fallbacks
let w5 = withDefault(nil)(Optional(42))  // Optional(42)
let w6 = withDefault(nil)(nil as Int?)   // nil  (fallback is itself nil)
```

### `fold` — collapse to a single value

```swift
let f1 = Optional(5).fold(onNone: 0, onSome: { $0 * 2 })    // 10
let f2 = (nil as Int?).fold(onNone: 0, onSome: { $0 * 2 })  // 0

// Static variant for point-free composition
let describe: @Sendable (Int?) -> String = Optional<Int>.fold(onNone: "nothing", onSome: { "value: \($0)" })
let f3 = describe(Optional(42))   // "value: 42"
let f4 = describe(nil)            // "nothing"
```

### `foldMap` — map to a Monoid, then combine

```swift
let fm1 = Optional(3).foldMap { Int.Monoids.Sum($0) }       // Sum(3)
let fm2 = (nil as Int?).foldMap { Int.Monoids.Sum($0) }     // Sum(0)  — Monoid identity

let fm3 = Optional("hello").foldMap { [$0] }   // ["hello"]
let fm4 = (nil as String?).foldMap { [$0] }    // []  — Array identity
```

### `toList` — zero-or-one element list

```swift
let l1 = Optional(42).toList   // [42]
let l2 = (nil as Int?).toList  // []
```

---

## `filter` — conditional nil

Applies a predicate. Returns `nil` if the predicate fails:

```swift
let fi1 = Optional(5).filter { $0 > 0 }    // Optional(5)
let fi2 = Optional(-1).filter { $0 > 0 }   // nil
let fi3 = (nil as Int?).filter { $0 > 0 }  // nil
```

---

## `then` — side effect on non-nil

Run a closure if the optional is non-nil, with an optional fallback for the `nil` case:

```swift
let t1 = Optional(42).then { print("Got \($0)") }           // prints "Got 42", returns Optional(42)
let t2 = (nil as Int?).then { print("Got \($0)") }          // nothing printed, returns nil

let t3 = Optional(42).then({ print("got: \($0)") }, otherwise: { print("nothing") })
// prints "got: 42"
```

---

## `isNilOrEmpty` — nil or empty collection

Available when `Wrapped` is a `Collection`:

```swift
let e1 = (nil as [Int]?).isNilOrEmpty      // true
let e2 = Optional([] as [Int]).isNilOrEmpty // true
let e3 = Optional([1, 2, 3]).isNilOrEmpty  // false

let e4 = (nil as String?).isNilOrEmpty     // true
let e5 = Optional("").isNilOrEmpty          // true
let e6 = Optional("hello").isNilOrEmpty    // false

// Optional(ifEmpty:) — wrap a collection, returning nil if empty
let e7 = Optional(ifEmpty: [] as [Int])    // nil
let e8 = Optional(ifEmpty: [1, 2])         // Optional([1, 2])
```

---

## Traverse

Useful for **inverting nested structures** — turning an `Optional` wrapping another type inside-out.
`sequence` is the common case: no mapping, just inversion.

```swift
// sequence :: [a]? -> [a?]   — Optional<Array> into Array<Optional>
let tr1 = Optional([1, 2, 3]).sequence()  // [Optional(1), Optional(2), Optional(3)]
let tr2 = (nil as [Int]?).sequence()      // [nil]  (single-element array containing nil)

// traverse :: (a -> [b]) -> a? -> [b?]   — map and invert at once
let tr3 = Optional("hi").traverse { [$0, $0 + "!"] }   // [Optional("hi"), Optional("hi!")]
let tr4 = (nil as String?).traverse { [$0, $0 + "!"] } // [nil]

// sequence :: Result<a,e>? -> Result<a?,e>   — Optional<Result> into Result<Optional>
let tr5 = Optional(Result<Int, Error>.success(42)).sequence()  // .success(Optional(42))
let tr6 = (nil as Result<Int, Error>?).sequence()              // .success(nil)
```

---

## Monad Transformers

Optional can be the **outer** layer of a transformer stack, threading another monad's effects
through it. Each stack is its own struct named `OptionalT{Inner}`: lift with the `.optionalT`
property (or `OptionalTArray(xs)`), use `map` / `flatMap` / the operators, and leave with `.rawValue`.
On a bare `[Int]?`, `map` and `<£>` are Optional's (they see the whole array).

### `OptionalTArray` (`[A]?`)

Optional wrapping an Array. `nil` propagates; `some([…])` operates on the Array.

```swift
import FP

let xs: [Int]? = [1, 2, 3]

// map: map inside the Array
let ot1 = xs.optionalT.map { $0 * 2 }.rawValue                // Optional([2, 4, 6])
let ot2 = (nil as [Int]?).optionalT.map { $0 * 2 }.rawValue   // nil

// liftA2: combine two [A]? values
let ot3 = OptionalTArray<Int>.liftA2(+)(OptionalTArray([1, 2]), OptionalTArray([10, 20])).rawValue
// Optional([11, 21, 12, 22]) (Array.liftA2 under Optional)

// flatMap: each element produces [B]?; nil in any result collapses to nil
let ot4 = xs.optionalT.flatMap { n in OptionalTArray([n, n * 10]) }.rawValue   // Optional([1, 10, 2, 20, 3, 30])
let ot5 = xs.optionalT.flatMap { n in OptionalTArray(n > 1 ? [n, n * 10] : nil) }.rawValue  // nil

// Operators
let ot6 = { $0 * 2 } <£> xs.optionalT                         // wraps Optional([2, 4, 6])
let ot7 = xs.optionalT >>- { n in OptionalTArray([n, n * 10]) }

// Escape hatch: the whole [Int]? (Compose-like stack, named by the outer layer)
let ot8 = xs.optionalT.mapOptionalT { $0 ?? [] }
```

### `OptionalTResult` (`Result<A, E>?`)

Optional wrapping a Result. `nil` propagates; `.some(.failure(e))` also propagates.

```swift
import FP

enum MyError: Error { case bad }

let okResult: Result<Int, MyError>? = .success(5)
let ot9 = okResult.optionalT.map { $0 * 2 }.rawValue      // Optional(.success(10))

let failResult: Result<Int, MyError>? = .failure(.bad)
let ot10 = failResult.optionalT.map { $0 * 2 }.rawValue   // Optional(.failure(.bad)), error preserved

let ot11 = (nil as Result<Int, MyError>?).optionalT.map { $0 * 2 }.rawValue  // nil

// flatMap: nil or failure short-circuit
let ot12 = okResult.optionalT.flatMap { n in OptionalTResult<MyError, Int>(n > 0 ? .success(n * 2) : nil) }.rawValue  // Optional(.success(10))
let ot13 = okResult.optionalT.flatMap { _ in OptionalTResult<MyError, Int>(nil) }.rawValue            // nil

// Operators
let ot14 = { $0 * 2 } <£> okResult.optionalT                       // wraps Optional(.success(10))
let ot15 = okResult.optionalT >>- { n in OptionalTResult<MyError, String>.pure("\(n)") }  // wraps Optional(.success("5"))
```

### `OptionalTEither` (`Either<L, A>?`)

Optional wrapping an Either. `nil` propagates; `.some(.left(l))` also propagates.

```swift
import DataStructure

let rightOpt: Either<String, Int>? = .right(5)
let ot16 = rightOpt.optionalT.map { $0 * 2 }.rawValue                         // Optional(.right(10))
let ot17 = rightOpt.optionalT.flatMap { n in .pure(n * 2) }.rawValue          // Optional(.right(10))

let ot18 = (nil as Either<String, Int>?).optionalT.map { $0 * 2 }.rawValue  // nil

let leftOpt: Either<String, Int>? = .left("err")
let ot19 = leftOpt.optionalT.map { $0 * 2 }.rawValue                      // Optional(.left("err"))
```

The other Optional-outer stacks are `OptionalTWriter` (`Writer<W, A>?`), `OptionalTNonEmpty`
(`NonEmpty<A>?`) and `OptionalTStateful` (`Stateful<S, A>?`, functor and applicative only), all in
`DataStructure`.

---

## Module

```swift
import FP        // Named functions (fmap, apply, seqRight, bind, kleisli…) and OptionalTArray / OptionalTResult
import CoreFPOperators  // Operators (<£>, <*>, >>-, >=>…)

// For OptionalTEither / OptionalTWriter / OptionalTNonEmpty / OptionalTStateful:
import DataStructure
import DataStructureOperators
```

---

## For Haskell developers

| This library | Haskell equivalent |
|---|---|
| `Optional<A>` | `Maybe a` |
| `.none` / `.some` | `Nothing` / `Just` |
| `<£>` / `<&>` (`fmap`) | `fmap` / `<$>` |
| `<*>` | `Applicative`'s `<*>` |
| `>>-` / `-<<` (`flatMap`) | `>>=` / `=<<` |
| `>=>` | `Control.Monad`'s `>=>` |
| `<|>` | `Alternative`'s `<|>` for `Maybe` |
| `fold(onNone:onSome:)` | `Data.Maybe`'s `maybe` |
| `withDefault` | `Data.Maybe`'s `fromMaybe` |
| `toList` | `Data.Maybe`'s `maybeToList` |
| `filter` | `Control.Monad`'s `mfilter` |
| `foldMap` | `Data.Foldable`'s `foldMap` |
| `sequence` / `traverse` | `Data.Traversable`'s `sequence` / `traverse` |

External references:
- [`Data.Maybe`](https://hackage.haskell.org/package/base/docs/Data-Maybe.html) — Haskell's base module for `Maybe`
- [`Control.Applicative`](https://hackage.haskell.org/package/base/docs/Control-Applicative.html) — defines `Alternative` and its `<|>` operator
