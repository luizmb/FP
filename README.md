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

Import the full library in one line:

```swift
import FP
```

Or import only what you need (granular options):

```swift
import CoreFP                  // Optional, Result, Array extensions + utilities
import CoreFPOperators         // Operators for all core types
import DataStructure         // Either, Reader, Stateful, Writer + transformer stacks
import DataStructureOperators // Operators for all data structures
```

---

## Custom Data Structures

### Either

`Either<Left, Right>` is a more flexible alternative to `Result`. While `Result` requires the error type to conform to `Error`, `Either` places no constraints on either side — making it ideal when your failure type is a `String`, a domain enum, or any non-`Error` type.

```swift
import DataStructure

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
import DataStructure

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

### `<£>` and `<&>` — Map (fmap) and flipped map

Apply a plain function to a value inside a container. `<£>` puts the function on the left; `<&>` puts the container on the left — use whichever reads more naturally.

```swift
{ $0 * 2 } <£> Optional(5)          // Optional(10)
{ $0 * 2 } <£> [1, 2, 3]            // [2, 4, 6]
{ $0 * 2 } <£> Result.success(5)    // .success(10)
{ $0 * 2 } <£> Either.right(5)      // .right(10)

Optional(5)       <&> { $0 * 2 }    // Optional(10)
Result.success(5) <&> { $0 * 2 }    // .success(10)
[1, 2, 3]         <&> { $0 * 2 }    // [2, 4, 6]
```

→ [Optional](docs/types/Optional.md#-and--map) · [Result](docs/types/Result.md#-and--map) · [Array](docs/types/Array.md#-and--map) · [Either](docs/types/Either.md#-and--map) · [Reader](docs/types/Reader.md#-and--map) · [Publisher](docs/types/Publisher.md#-and--map) · [AsyncSequence](docs/types/AsyncSequence.md#-and--map)

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

### `>>-` and `-<<` — Bind (flatMap) and flipped bind

Chain operations where each step may fail, produce multiple values, or have other effects. `>>-` puts the container on the left; `-<<` puts the function on the left.

```swift
Optional("42") >>- { Int($0) }                   // Optional(42)
Optional("??") >>- { Int($0) }                   // nil
[1, 2, 3]      >>- { [$0, $0 * 10] }            // [1, 10, 2, 20, 3, 30]
Result.success("42") >>- { parse($0) }           // .success(42)  or .failure(…)

{ Int($0) }       -<< Optional("42")             // Optional(42)
{ [$0, $0 * 10] } -<< [1, 2, 3]                 // [1, 10, 2, 20, 3, 30]
```

→ [Optional](docs/types/Optional.md#---and---bind-flatmap) · [Result](docs/types/Result.md#---and---bind-flatmap) · [Array](docs/types/Array.md#---and---bind-flatmap) · [Either](docs/types/Either.md#---and---bind-flatmap) · [Reader](docs/types/Reader.md#---and---bind-flatmap) · [Publisher](docs/types/Publisher.md#---and---bind-flatmap) · [AsyncSequence](docs/types/AsyncSequence.md#---and---bind-flatmap)

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

### `>>>` — Function composition

Compose two functions left-to-right. `f >>> g` is equivalent to `{ g(f($0)) }`.

```swift
let addOne  = { (x: Int) in x + 1 }
let double  = { (x: Int) in x * 2 }

let pipeline = addOne >>> double
pipeline(5)   // 12  (add one → double)
```

---

### `|>` — Pipe

Apply a value to a function left-to-right. Reads as a data pipeline.

```swift
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

## Monad Transformers

Every type can act as the **outer** layer of a transformer stack, threading another monad's effects through it. All stacks have the same three operations: `mapT` (Functor), `liftA2*` (Applicative), and `flatMapT` (Monad). All existing operators — `<£>`, `<*>`, `>>-`, `>=>` — are overloaded to work on each stack.

### T-naming convention

| Swift type | Transformer name | Haskell equivalent |
|---|---|---|
| `[A]?` | `OptionalTArray` | `ListT Maybe` |
| `Result<A,E>?` | `OptionalTResult` | `ExceptT e Maybe` |
| `Either<L,A>?` | `OptionalTEither` | `ExceptT l Maybe` |
| `[A?]` | `ArrayTOptional` | `MaybeT []` |
| `[Result<A,E>]` | `ArrayTResult` | `ExceptT e []` |
| `[Either<L,A>]` | `ArrayTEither` | `ExceptT l []` |
| `Either<L, A?>` | `EitherTOptional` | `MaybeT (Either l)` |
| `Either<L, [A]>` | `EitherTArray` | `ListT (Either l)` |
| `AnyPublisher<A?,E>` | `PublisherTOptional` | `MaybeT Publisher` |
| `AnyPublisher<[A],E>` | `PublisherTArray` | `ListT Publisher` |
| `AsyncStream<A?>` | `AsyncSequenceTOptional` | `MaybeT AsyncStream` |
| `AsyncStream<[A]>` | `AsyncSequenceTArray` | `ListT AsyncStream` |
| … and more | | |

```swift
// [A]? — OptionalTArray (ListT Maybe)
// mapT maps inside the Array, leaving the Optional layer alone
let xs: [Int]? = [1, 2, 3]
xs.mapT { $0 * 2 }          // Optional([2, 4, 6])
(nil as [Int]?).mapT { $0 * 2 }  // nil

// flatMapT: nil propagates; each element can produce [B]?
xs.flatMapT { n in n > 1 ? [n, n * 10] : nil }  // nil (nil short-circuits)
xs.flatMapT { n in [n, n * 10] }                 // Optional([1, 10, 2, 20, 3, 30])

// [A?] — ArrayTOptional (MaybeT [])
// nil elements stay nil, non-nil elements are transformed
let ys: [Int?] = [1, nil, 3]
ys.mapT { $0 * 2 }           // [Optional(2), nil, Optional(6)]
ys.flatMapT { n in [n, n + 1] }  // [Optional(1), Optional(2), nil, Optional(3), Optional(4)]

// [Either<L,A>] — ArrayTEither (ExceptT l [])
// .left propagates; .right elements proceed
let zs: [Either<String, Int>] = [.right(1), .left("err"), .right(3)]
zs.mapT { $0 * 2 }              // [.right(2), .left("err"), .right(6)]
zs.flatMapT { n in [.right(n * 2)] }  // [.right(2), .left("err"), .right(6)]

// Either<L, [A]> — EitherTArray (ListT (Either l))
// flatMapT applies fn to each element and combines results
let e: Either<String, [Int]> = .right([1, 2, 3])
flatMapTEitherArray(e) { n in .right([n, n * 10]) }
// .right([1, 10, 2, 20, 3, 30])
```

→ [Optional transformers](docs/types/Optional.md#monad-transformers) · [Array transformers](docs/types/Array.md#monad-transformers) · [Either transformers](docs/types/Either.md#monad-transformers) · [Publisher transformers](docs/types/Publisher.md#monad-transformers) · [AsyncSequence transformers](docs/types/AsyncSequence.md#monad-transformers)

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

548 tests covering functor/applicative/monad laws, all operators, and all transformer combinations.

```bash
swift test
# Executed 548 tests, with 0 failures
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
