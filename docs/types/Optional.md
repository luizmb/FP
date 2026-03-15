# Optional

Swift's `Optional` extended with functional operators and named functions.

An `Optional<A>` is either `.some(value)` or `.none`. The operators let you transform, combine, and chain optional values without manual unwrapping.

---

## `<£>` — Map

Apply a function to the wrapped value. If the optional is `nil`, the result is `nil`.

```swift
{ $0 * 2 } <£> Optional(5)    // Optional(10)
{ $0 * 2 } <£> (nil as Int?)  // nil

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

## `<&>` — Flipped map

Same as `<£>` with the optional on the left. Reads naturally left-to-right.

```swift
Optional(5) <&> { $0 * 2 }   // Optional(10)
(nil as Int?) <&> { $0 * 2 } // nil

// Named function
Optional(5).map { $0 * 2 }   // Optional(10)
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

## `>>-` — Bind (flatMap)

Chain operations that each may return `nil`. Stops at the first `nil`.

```swift
Optional("42") >>- { Int($0) }                          // Optional(42)
Optional("??") >>- { Int($0) }                          // nil
Optional(42) >>- { $0 > 0 ? .some($0 * 2) : nil }      // Optional(84)
Optional(-1) >>- { $0 > 0 ? .some($0 * 2) : nil }      // nil

// Chained
Optional("42") >>- { Int($0) } >>- { $0 > 0 ? .some($0) : nil }  // Optional(42)

// Named function
Optional.bind { Int($0) }(Optional("42"))  // Optional(42)
Optional("42").flatMap { Int($0) }         // Optional(42)
```

---

## `-<<` — Flipped bind

Same as `>>-` with arguments reversed. Useful for naming the function first.

```swift
{ Int($0) } -<< Optional("42")   // Optional(42)
{ Int($0) } -<< Optional("??")   // nil
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

## Module

```swift
import FP       // Named functions (fmap, apply, seqRight, bind, kleisli…)
import Operators // Operators (<£>, <*>, >>-, >=>…)
```
