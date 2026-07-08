# ``Swift/Optional``

Swift's `Optional` extended with functional operators and named functions.

An `Optional<A>` is either `.some(value)` or `.none`. The operators let you transform, combine, and chain optional values without manual unwrapping.

---

## `<£>` and `<&>` — Map

Apply a function to the wrapped value. `<£>` puts the function on the left; `<&>` puts the optional on the left.

```swift
{ $0 * 2 } <£> Optional(5)    // Optional(10)
{ $0 * 2 } <£> (nil as Int?)  // nil

Optional(5)       <&> { $0 * 2 }   // Optional(10)
(nil as Int?)     <&> { $0 * 2 }   // nil

// Named function
Optional.fmap { $0 * 2 }(Optional(5))  // Optional(10)
Optional(5).map { $0 * 2 }             // Optional(10)
```

---

## `£>` and `<£` — Replace

Replace the wrapped value with a constant, keeping the `nil`/non-`nil` structure.

```swift
Optional(42) £> "hello"   // Optional("hello")
(nil as Int?) £> "hello"  // nil

"hello" <£ Optional(42)   // Optional("hello")
"hello" <£ (nil as Int?)  // nil

// Named function (fmap with const)
Optional.fmap(const("hello"))(Optional(42))  // Optional("hello")
```

---

## `<*>` — Apply

Apply a function that is itself optional to an optional value. Both must be non-`nil`.

```swift
Optional({ $0 * 2 }) <*> Optional(5)         // Optional(10)
Optional({ $0 * 2 }) <*> (nil as Int?)        // nil
(nil as ((Int) -> Int)?) <*> Optional(5)      // nil

// Named function
Optional.apply(Optional({ $0 * 2 }), Optional(5))  // Optional(10)
```

---

## `*>` and `<*` — Sequence

Run two optionals in sequence, keeping only one side's value. If either is `nil`, the result is `nil`.

```swift
Optional("a") *> Optional("b")        // Optional("b")
(nil as String?) *> Optional("b")     // nil
Optional("a") *> (nil as String?)     // nil

Optional("a") <* Optional("b")        // Optional("a")
Optional("a") <* (nil as String?)     // nil

// Named functions
Optional("a").seqRight(Optional("b")) // Optional("b")
Optional("a").seqLeft(Optional("b"))  // Optional("a")
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain operations that each may return `nil`. `>>-` puts the container on the left; `-<<` puts the function on the left.

```swift
Optional("42") >>- { Int($0) }                          // Optional(42)
Optional("??") >>- { Int($0) }                          // nil
Optional(42) >>- { $0 > 0 ? .some($0 * 2) : nil }      // Optional(84)
Optional(-1) >>- { $0 > 0 ? .some($0 * 2) : nil }      // nil

// Chained
Optional("42") >>- { Int($0) } >>- { $0 > 0 ? .some($0) : nil }  // Optional(42)

{ Int($0) } -<< Optional("42")   // Optional(42)
{ Int($0) } -<< Optional("??")   // nil

// Named function
Optional.bind { Int($0) }(Optional("42"))  // Optional(42)
Optional("42").flatMap { Int($0) }         // Optional(42)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return an `Optional`, producing a single function.

```swift
let parseInt:    (String) -> Int? = { Int($0) }
let toPositive:  (Int)    -> Int? = { $0 > 0 ? $0 : nil }
let doublePositive: (Int) -> Int? = { $0 > 0 ? $0 * 2 : nil }

let parsePositive = parseInt >=> toPositive
parsePositive("42")   // Optional(42)
parsePositive("-1")   // nil
parsePositive("??")   // nil

// Three-way composition
let pipeline = parseInt >=> toPositive >=> doublePositive
pipeline("21")   // Optional(42)
pipeline("-1")   // nil

// Named function
Optional.kleisli(parseInt, toPositive)("42")  // Optional(42)
```

---

## `<|>` — Alternative

Return the first non-`nil` value.

```swift
(nil as Int?) <|> Optional(3)    // Optional(3)
Optional(1)   <|> Optional(3)    // Optional(1)
(nil as Int?) <|> (nil as Int?)  // nil
```

---

## Fold (Foldable)

### `withDefault` — provide a fallback

`withDefault` is a curried function for point-free composition. It replaces `nil` with a fallback value:

```swift
withDefault(0)(Optional(42))   // 42
withDefault(0)(nil)            // 0

// Curried version — useful in pipelines
let safeAge: (String) -> Int = { Int($0) } >>> withDefault(0)
safeAge("25")   // 25
safeAge("??")   // 0

// Two-argument version — provides a chain of fallbacks
withDefault(nil)(Optional(42))  // Optional(42)
withDefault(nil)(nil as Int?)   // nil  (fallback is itself nil)
```

### `fold` — collapse to a single value

```swift
Optional(5).fold(onNone: 0, onSome: { $0 * 2 })    // 10
(nil as Int?).fold(onNone: 0, onSome: { $0 * 2 })  // 0

// Static variant for point-free composition
let describe: (Int?) -> String = Optional.fold(onNone: "nothing", onSome: { "value: \($0)" })
describe(Optional(42))   // "value: 42"
describe(nil)            // "nothing"
```

### `foldMap` — map to a Monoid, then combine

```swift
Optional(3).foldMap { Int.Monoids.Sum($0) }       // Sum(3)
(nil as Int?).foldMap { Int.Monoids.Sum($0) }     // Sum(0)  — Monoid identity

Optional("hello").foldMap { [$0] }   // ["hello"]
(nil as String?).foldMap { [$0] }    // []  — Array identity
```

### `toList` — zero-or-one element list

```swift
Optional(42).toList   // [42]
(nil as Int?).toList  // []
```

---

## `filter` — conditional nil

Applies a predicate. Returns `nil` if the predicate fails:

```swift
Optional(5).filter { $0 > 0 }    // Optional(5)
Optional(-1).filter { $0 > 0 }   // nil
(nil as Int?).filter { $0 > 0 }  // nil
```

---

## `then` — side effect on non-nil

Run a closure if the optional is non-nil, with an optional fallback for the `nil` case:

```swift
Optional(42).then { print("Got \($0)") }           // prints "Got 42", returns Optional(42)
(nil as Int?).then { print("Got \($0)") }           // nothing printed, returns nil

Optional(42).then({ print("got: \($0)") }, otherwise: { print("nothing") })
// prints "got: 42"
```

---

## `isNilOrEmpty` — nil or empty collection

Available when `Wrapped` is a `Collection`:

```swift
(nil as [Int]?).isNilOrEmpty      // true
Optional([]).isNilOrEmpty          // true
Optional([1, 2, 3]).isNilOrEmpty  // false

(nil as String?).isNilOrEmpty     // true
Optional("").isNilOrEmpty          // true
Optional("hello").isNilOrEmpty    // false

// Optional(ifEmpty:) — wrap a collection, returning nil if empty
Optional(ifEmpty: [])      // nil
Optional(ifEmpty: [1, 2])  // Optional([1, 2])
```

---

## Traverse

Useful for **inverting nested structures** — turning an `Optional` wrapping another type inside-out.
`sequence` is the common case: no mapping, just inversion.

```swift
// sequence :: [a]? -> [a?]   — Optional<Array> into Array<Optional>
Optional([1, 2, 3]).sequence()  // [Optional(1), Optional(2), Optional(3)]
(nil as [Int]?).sequence()      // [nil]  (single-element array containing nil)

// traverse :: (a -> [b]) -> a? -> [b?]   — map and invert at once
Optional("hi").traverse { [$0, $0 + "!"] }   // [Optional("hi"), Optional("hi!")]
(nil as String?).traverse { [$0, $0 + "!"] } // [nil]

// sequence :: Result<a,e>? -> Result<a?,e>   — Optional<Result> into Result<Optional>
Optional(Result<Int, Error>.success(42)).sequence()  // .success(Optional(42))
(nil as Result<Int, Error>?).sequence()              // .success(nil)
```

---

## Monad Transformers

Optional can be the **outer** layer of a transformer stack, threading another monad's effects through it. The transformer name is `OptionalT{Inner}`.

### `OptionalTArray` — `[A]?`

Optional wrapping an Array. `nil` propagates; `some([…])` operates on the Array.

```swift
import FP

// mapT — map inside the Array
let xs: [Int]? = [1, 2, 3]
xs.mapT { $0 * 2 }                  // Optional([2, 4, 6])
(nil as [Int]?).mapT { $0 * 2 }     // nil

// liftA2 — combine two [A]? values
liftA2OptionalArray(+)(Optional([1, 2]), Optional([10, 20]))
// Optional([11, 21, 12, 22])   — Array.liftA2 under Optional

// flatMapT — each element produces [B]?; nil in any result collapses to nil
xs.flatMapT { n in [n, n * 10] }    // Optional([1, 10, 2, 20, 3, 30])
xs.flatMapT { n in n > 1 ? [n, n * 10] : nil }  // nil

// Operators
{ $0 * 2 } <£> xs                   // Optional([2, 4, 6])
xs >>- { n in [n, n * 10] }         // Optional([1, 10, 2, 20, 3, 30])
```

### `OptionalTResult` — `Result<A,E>?`

Optional wrapping a Result. `nil` propagates; `.some(.failure(e))` also propagates.

```swift
import FP

let r: Result<Int, MyError>? = .success(5)
r.mapT { $0 * 2 }              // Optional(.success(10))

let fail: Result<Int, MyError>? = .failure(.bad)
fail.mapT { $0 * 2 }           // Optional(.failure(.bad))  — error preserved

(nil as Result<Int, MyError>?).mapT { $0 * 2 }  // nil

// flatMapT — nil or failure short-circuit
r.flatMapT { n in n > 0 ? .success(n * 2) : nil }  // Optional(.success(10))
r.flatMapT { _ in nil }                              // nil

// Operators
{ $0 * 2 } <£> r    // Optional(.success(10))
r >>- { n in .success("\(n)") }  // Optional(.success("5"))
```

### `OptionalTEither` — `Either<L,A>?`

Optional wrapping an Either. `nil` propagates; `.some(.left(l))` also propagates.

```swift
import DataStructure

let e: Either<String, Int>? = .right(5)
e.mapT { $0 * 2 }              // Optional(.right(10))
e.flatMapT { n in .right(n * 2) }  // Optional(.right(10))

(nil as Either<String, Int>?).mapT { $0 * 2 }  // nil

let left: Either<String, Int>? = .left("err")
left.mapT { $0 * 2 }           // Optional(.left("err"))
```

---

## Module

```swift
import FP        // Named functions (fmap, apply, seqRight, bind, kleisli…)
import CoreFPOperators  // Operators (<£>, <*>, >>-, >=>…)

// For Either-inner transformers:
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
