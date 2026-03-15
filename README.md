# FP

Functional Programming utilities for Swift — operators, data structures, and patterns inspired by Haskell.

> New to functors, applicatives, and monads? [Functors, Applicatives, and Monads in Pictures](https://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html) is a great starting point.

---

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/luizmb/FP.git", from: "1.0.0")
]
```

Import only what you need:

```swift
import FP          // Optional, Result, Array extensions + utilities
import Either      // Either type
import Reader      // Reader monad
import Operators   // Operators for all core types
```

---

## Custom Data Structures

### Either

`Either<Left, Right>` is a more flexible alternative to `Result`. While `Result` requires the error type to conform to `Error`, `Either` places no constraints on either side — making it ideal when your failure type is a `String`, a domain enum, or any non-`Error` type.

```swift
import Either

func divide(_ a: Double, by b: Double) -> Either<String, Double> {
    b == 0 ? .left("Division by zero") : .right(a / b)
}

divide(10, by: 2) <£> { $0 * 3 }              // .right(15.0)
divide(10, by: 0) <£> { $0 * 3 }              // .left("Division by zero")
divide(10, by: 2) >>- { divide($0, by: 2) }   // .right(2.5)
```

→ [Full Either documentation](docs/types/Either.md)

---

### Reader

`Reader<Environment, Output>` wraps a function `(Environment) -> Output`. It solves the **dependency injection** problem: describe computations that need a dependency, compose them freely, and provide the dependency once at the edge — no globals, no singletons, no passing it through every call.

```swift
import Reader

protocol Storage {
    func load(key: String) -> String?
}

let loadUsername = Reader<any Storage, String?> { $0.load(key: "username") }
let greeting     = loadUsername.mapReader { $0.map { "Hello, \($0)!" } }

greeting(UserDefaults.standard)  // Optional("Hello, Alice!")  — production
greeting(MockStorage(data: …))   // Optional("Hello, Test!")   — tests
```

→ [Full Reader documentation](docs/types/Reader.md)

---

## Operators

All operators work uniformly across `Optional`, `Result`, `Array`, `Either`, `Reader`, `Publisher`, and `AsyncStream`. The sections below show a quick example on two or three types — follow the links for the full picture including named function equivalents.

---

### `<£>` — Map (fmap)

Apply a plain function to a value inside a container.

```swift
{ $0 * 2 } <£> Optional(5)          // Optional(10)
{ $0 * 2 } <£> [1, 2, 3]            // [2, 4, 6]
{ $0 * 2 } <£> Result.success(5)    // .success(10)
{ $0 * 2 } <£> Either.right(5)      // .right(10)
```

→ [Optional](docs/types/Optional.md#-map) · [Result](docs/types/Result.md#-map) · [Array](docs/types/Array.md#-map) · [Either](docs/types/Either.md#-map) · [Reader](docs/types/Reader.md#-map) · [Publisher](docs/types/Publisher.md#-map) · [AsyncSequence](docs/types/AsyncSequence.md#-map)

---

### `£>` and `<£` — Replace

Replace the wrapped value with a constant, keeping the structure.

```swift
Optional(42) £> "done"            // Optional("done")
[1, 2, 3]    £> 0                 // [0, 0, 0]
"done" <£ Result.success(42)      // .success("done")
```

→ [Optional](docs/types/Optional.md#-and--replace) · [Result](docs/types/Result.md#-and--replace) · [Array](docs/types/Array.md#-and--replace) · [Either](docs/types/Either.md#-and--replace) · [Reader](docs/types/Reader.md#-and--replace) · [Publisher](docs/types/Publisher.md#-and--replace)

---

### `<&>` — Flipped map

Same as `<£>` with the container on the left. Reads naturally in pipelines.

```swift
Optional(5)       <&> { $0 * 2 }   // Optional(10)
Result.success(5) <&> { $0 * 2 }   // .success(10)
[1, 2, 3]         <&> { $0 * 2 }   // [2, 4, 6]
```

---

### `<*>` — Apply

Apply a function that is itself inside a container to a value inside a container.

```swift
Optional({ $0 * 2 })           <*> Optional(5)    // Optional(10)
[{ $0 + 1 }, { $0 * 10 }]     <*> [1, 2]         // [2, 3, 10, 20]
Result.success({ $0 * 2 })     <*> .success(5)    // .success(10)
```

→ [Optional](docs/types/Optional.md#-apply) · [Result](docs/types/Result.md#-apply) · [Array](docs/types/Array.md#-apply) · [Either](docs/types/Either.md#-apply) · [Reader](docs/types/Reader.md#-apply) · [Publisher](docs/types/Publisher.md#-apply) · [AsyncSequence](docs/types/AsyncSequence.md#-apply)

---

### `*>` and `<*` — Sequence

Run two containers in sequence, keeping only one side's value. Any failure/nil propagates.

```swift
Optional("a") *> Optional("b")        // Optional("b")
nil           *> Optional("b")        // nil
[1, 2]        *> ["a", "b"]           // ["a", "b", "a", "b"]
Result.success("a") <* .success("b")  // .success("a")
```

→ [Optional](docs/types/Optional.md#-and--sequence) · [Result](docs/types/Result.md#-and--sequence) · [Array](docs/types/Array.md#-and--sequence) · [Either](docs/types/Either.md#-and--sequence) · [Reader](docs/types/Reader.md#-and--sequence) · [Publisher](docs/types/Publisher.md#-and--sequence) · [AsyncSequence](docs/types/AsyncSequence.md#-and--sequence)

---

### `>>-` — Bind (flatMap)

Chain operations where each step may fail, produce multiple values, or have other effects.

```swift
Optional("42") >>- { Int($0) }                   // Optional(42)
Optional("??") >>- { Int($0) }                   // nil
[1, 2, 3]      >>- { [$0, $0 * 10] }            // [1, 10, 2, 20, 3, 30]
Result.success("42") >>- { parse($0) }           // .success(42)  or .failure(…)
```

→ [Optional](docs/types/Optional.md#--bind-flatmap) · [Result](docs/types/Result.md#--bind-flatmap) · [Array](docs/types/Array.md#--bind-flatmap) · [Either](docs/types/Either.md#--bind-flatmap) · [Reader](docs/types/Reader.md#--bind-flatmap) · [Publisher](docs/types/Publisher.md#--bind-flatmap) · [AsyncSequence](docs/types/AsyncSequence.md#--bind-flatmap)

---

### `-<<` — Flipped bind

Same as `>>-` with arguments reversed. Useful when naming the function first.

```swift
{ Int($0) }       -<< Optional("42")    // Optional(42)
{ [$0, $0 * 10] } -<< [1, 2, 3]        // [1, 10, 2, 20, 3, 30]
```

---

### `>=>` — Kleisli composition

Compose two functions that each return a value in a context, like `>>>` for monadic functions.

```swift
let parseInt:   (String) -> Int?          = { Int($0) }
let toPositive: (Int)    -> Int?          = { $0 > 0 ? $0 : nil }

let parsePositive = parseInt >=> toPositive
parsePositive("42")   // Optional(42)
parsePositive("-1")   // nil
parsePositive("??")   // nil
```

→ [Optional](docs/types/Optional.md#--kleisli-composition) · [Result](docs/types/Result.md#--kleisli-composition) · [Array](docs/types/Array.md#--kleisli-composition) · [Either](docs/types/Either.md#--kleisli-composition) · [Reader](docs/types/Reader.md#--kleisli-composition) · [Publisher](docs/types/Publisher.md#--kleisli-composition)

---

### `>>>` and `|>` — Function composition and pipe

```swift
let addOne  = { (x: Int) in x + 1 }
let double  = { (x: Int) in x * 2 }

let pipeline = addOne >>> double
pipeline(5)          // 12

5 |> addOne |> double  // 12
```

---

### `<>` — Semigroup append

Combine two values that support appending.

```swift
[1, 2]      <> [3, 4]          // [1, 2, 3, 4]
"Hello, "   <> "world!"        // "Hello, world!"
Optional(5) <> nil             // Optional(5)
nil         <> Optional(3)     // Optional(3)
```

---

### `<|>` — Alternative

Return the first successful / non-empty value.

```swift
nil           <|> Optional(3)    // Optional(3)
Optional(1)   <|> Optional(3)    // Optional(1)
[]            <|> [1, 2, 3]      // [1, 2, 3]
```

---

## Traverse

Useful for **inverting nested structures** — turning an `Array` of `Optional` elements into a single `Optional` wrapping an `Array`, and similar inversions.

```swift
// [a?] -> [a]?   — if any element is nil, the whole result is nil
[Optional(1), Optional(2), Optional(3)].sequence()  // Optional([1, 2, 3])
[Optional(1), nil,         Optional(3)].sequence()  // nil

// [Result<a,e>] -> Result<[a],e>   — stops at the first failure
[Result.success(1), .success(2), .success(3)].sequence()   // .success([1, 2, 3])
[Result.success(1), .failure(err), .success(3)].sequence() // .failure(err)

// [[a]] -> [[a]]   — cartesian product
[[1, 2], [3, 4]].sequence()   // [[1,3], [1,4], [2,3], [2,4]]
```

→ [Optional](docs/types/Optional.md#traverse) · [Result](docs/types/Result.md#traverse) · [Array](docs/types/Array.md#traverse)

---

## Testing

378 tests covering functor/applicative/monad laws, all operators, and all transformer combinations.

```bash
swift test
# Executed 378 tests, with 0 failures
```

---

## Platform Support

| Platform | Minimum |
|----------|---------|
| macOS    | 10.15+  |
| iOS      | 13.0+   |
| tvOS     | 13.0+   |
| watchOS  | 6.0+    |

Combine features require macOS 13.0+ / iOS 16.0+. Linux is supported for non-Combine modules.

---

## License

MIT
