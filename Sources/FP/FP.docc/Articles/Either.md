# Either

`Either<Left, Right>` is a type with exactly two possible cases: `.left(Left)` or `.right(Right)`.

It solves the same problem as `Result` — representing success or failure — but without requiring the error type to conform to `Error`. By convention the right side is the "happy path" and the left is the failure, but both sides are equal citizens and can hold any type. This makes `Either` more flexible when your error type is a simple enum, a `String`, or any non-`Error` type.

```swift
import Either

func divide(_ a: Double, by b: Double) -> Either<String, Double> {
    b == 0 ? .left("Division by zero") : .right(a / b)
}
```

---

## `<£>` and `<&>` — Map

Apply a function to the right value. `<£>` puts the function on the left; `<&>` puts the either on the left.

```swift
{ $0 * 2 } <£> Either<String, Int>.right(5)       // .right(10)
{ $0 * 2 } <£> Either<String, Int>.left("error")  // .left("error")

Either<String, Int>.right(5)      <&> { $0 * 2 }  // .right(10)
Either<String, Int>.left("error") <&> { $0 * 2 }  // .left("error")

// Named function
Either<String, Int>.fmap { $0 * 2 }(.right(5))  // .right(10)
Either.right(5).mapRight { $0 * 2 }             // .right(10)
```

---

## `£>` and `<£` — Replace

Replace the right value with a constant. Left values pass through unchanged.

```swift
Either<String, Int>.right(42) £> "done"    // .right("done")
Either<String, Int>.left("err") £> "done"  // .left("err")

"done" <£ Either<String, Int>.right(42)    // .right("done")
```

---

## `<*>` — Apply

Apply a function in an `Either` to a value in an `Either`. Both must be `.right`.

```swift
Either<String, (Int) -> Int>.right({ $0 * 2 }) <*> .right(5)      // .right(10)
Either<String, (Int) -> Int>.right({ $0 * 2 }) <*> .left("error") // .left("error")
Either<String, (Int) -> Int>.left("no fn")      <*> .right(5)     // .left("no fn")

// Named function
Either.apply(.right({ $0 * 2 }), .right(5))  // .right(10)
```

---

## `*>` and `<*` — Sequence

Run two eithers in sequence, keeping only one side's value. Any left propagates.

```swift
Either<String, Int>.right(1) *> .right(2)      // .right(2)
Either<String, Int>.left("err") *> .right(2)   // .left("err")
Either<String, Int>.right(1) *> .left("err")   // .left("err")

Either<String, Int>.right(1) <* .right(2)      // .right(1)
Either<String, Int>.right(1) <* .left("err")   // .left("err")

// Named functions
Either.right(1).seqRight(.right(2))  // .right(2)
Either.right(1).seqLeft(.right(2))   // .right(1)
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain operations that each may produce a left. `>>-` puts the container on the left; `-<<` puts the function on the left.

```swift
func parse(_ s: String) -> Either<String, Int> {
    Int(s).map(Either.right) ?? .left("Not a number: \(s)")
}
func validate(_ n: Int) -> Either<String, Int> {
    n > 0 ? .right(n) : .left("Must be positive: \(n)")
}

Either.right("42") >>- parse >>- validate    // .right(42)
Either.right("-1") >>- parse >>- validate    // .left("Must be positive: -1")
Either.right("??") >>- parse                 // .left("Not a number: ??")

validate -<< Either.right(42)   // .right(42)
validate -<< Either.right(-1)   // .left("Must be positive: -1")

// Named function
Either.right("42").flatMap(parse)  // .right(42)
Either.bind(validate)(.right(42))  // .right(42)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return an `Either`.

```swift
let pipeline = parse >=> validate
pipeline("42")   // .right(42)
pipeline("-1")   // .left("Must be positive: -1")
pipeline("??")   // .left("Not a number: ??")

// Named function
Either.kleisli(parse, validate)("42")  // .right(42)
```

---

## `<|>` — Alternative

Return the first `.right`, or the last `.left` if both fail.

```swift
Either<String, Int>.left("a") <|> .right(3)    // .right(3)
Either<String, Int>.right(1)  <|> .right(3)    // .right(1)
Either<String, Int>.left("a") <|> .left("b")   // .left("b")
```

---

## Mapping both sides

`Either` supports mapping either side independently.

```swift
// mapLeft — transform the left (failure) side
Either<String, Int>.left("error").mapLeft { $0.uppercased() }  // .left("ERROR")
Either<String, Int>.right(42).mapLeft { $0.uppercased() }      // .right(42)

// bimap — transform both sides at once
Either<String, Int>.right(42).bimap(
    lf: { $0.uppercased() },
    rf: { $0 * 2 }
)  // .right(84)

Either<String, Int>.left("error").bimap(
    lf: { $0.uppercased() },
    rf: { $0 * 2 }
)  // .left("ERROR")
```

---

## Monad Transformers

Either participates in transformer stacks in two ways: as the **outer** layer (`EitherT{Inner}`) or as the **inner** layer (`{Outer}TEither`).

### `EitherTOptional` — `Either<L, A?>` (outer = Either, inner = Optional)

Either containing an Optional. `.left` propagates; `.right(.none)` re-wraps as `.right(.none)`.

```swift
import Either

let e: Either<String, Int?> = .right(.some(5))
mapTEitherOptional({ $0 * 2 }, e)          // .right(Optional(10))
flatMapTEitherOptional(e) { n in .right(.some(n * 2)) }  // .right(Optional(10))

let none: Either<String, Int?> = .right(.none)
flatMapTEitherOptional(none) { n in .right(.some(n * 2)) }  // .right(nil)  — nothing to bind

let left: Either<String, Int?> = .left("err")
flatMapTEitherOptional(left) { n in .right(.some(n * 2)) }  // .left("err")

// Operators
{ $0 * 2 } <£> e   // .right(Optional(10))
e >>- { n in .right(.some(n + 1)) }
```

### `EitherTArray` — `Either<L, [A]>` (outer = Either, inner = Array)

Either containing an Array. `.left` propagates; `.right(arr)` lets you flatMap over elements.

```swift
import Either

let e: Either<String, [Int]> = .right([1, 2, 3])
mapTEitherArray({ $0 * 2 }, e)         // .right([2, 4, 6])
flatMapTEitherArray(e) { n in .right([n, n * 10]) }  // .right([1, 10, 2, 20, 3, 30])

Either<String, [Int]>.left("err")
  |> { flatMapTEitherArray($0) { n in .right([n]) } }  // .left("err")
```

### `EitherTResult` — `Either<L, Result<A,E>>` (outer = Either, inner = Result)

Either containing a Result — two independent error channels.

```swift
import Either

let e: Either<String, Result<Int, MyError>> = .right(.success(5))
mapTEitherResult({ $0 * 2 }, e)         // .right(.success(10))
flatMapTEitherResult(e) { n in .right(.success(n * 2)) }  // .right(.success(10))

// Inner failure preserves outer .right
let innerFail: Either<String, Result<Int, MyError>> = .right(.failure(.bad))
flatMapTEitherResult(innerFail) { n in .right(.success(n)) }  // .right(.failure(.bad))
```

### `OptionalTEither` — `Either<L,A>?` (outer = Optional, inner = Either)

Optional wrapping an Either. `nil` propagates; `.some(.left(l))` also propagates.

```swift
import Either

let e: Either<String, Int>? = .right(5)
e.mapT { $0 * 2 }                       // Optional(.right(10))
e.flatMapT { n in .right(n * 2) }       // Optional(.right(10))

(nil as Either<String, Int>?).mapT { $0 * 2 }   // nil

let left: Either<String, Int>? = .left("err")
left.mapT { $0 * 2 }                    // Optional(.left("err"))
```

### `ArrayTEither` — `[Either<L,A>]` (outer = Array, inner = Either)

Array of Either values. `.left` elements propagate; `.right` elements are transformed.

```swift
import Either

let es: [Either<String, Int>] = [.right(1), .left("err"), .right(3)]
es.mapT { $0 * 2 }              // [.right(2), .left("err"), .right(6)]
es.flatMapT { n in [.right(n), .right(n * 10)] }
// [.right(1), .right(10), .left("err"), .right(3), .right(30)]
```

---

## Module

```swift
import Either          // Either type + named functions + transformer implementations
import EitherOperators // Operators (<£>, <*>, >>-, >=>…) for Either and all EitherT stacks
```

---

## For Haskell developers

| This library | Haskell equivalent |
|---|---|
| `Either<Left, Right>` | `Data.Either`'s `Either a b` |
| `.left` / `.right` | `Left` / `Right` |
| `<£>` / `<&>` (`fmap`) | `fmap` / `<$>` — note: Haskell's `Functor` instance for `Either a` maps over `Right` only, exactly matching this library's `mapRight` |
| `bimap` | `Data.Bifunctor`'s `bimap` |
| `mapLeft` | `Data.Bifunctor`'s `first` |
| `<*>` | `Applicative`'s `<*>` (short-circuits on the first `Left`) |
| `>>-` / `-<<` (`flatMap`) | `>>=` / `=<<` |
| `>=>` | `Control.Monad`'s `>=>` (and `<=<` for the flipped direction) |
| `<|>` | not in `base` — `Either`'s `Applicative`/`Monad` has no canonical identity element, so `base` doesn't define `Alternative` for it; some ecosystems (e.g. `semigroupoids`' `Alt`) add an equivalent choice operator without requiring one |
| `EitherTOptional`, `EitherTArray`, `EitherTResult`, `OptionalTEither`, `ArrayTEither` | `transformers`' `ExceptT e m a` — the modern replacement for the older, now-deprecated `EitherT` from the `either` package |

External references:
- [`Data.Either`](https://hackage.haskell.org/package/base/docs/Data-Either.html) — Haskell's base module for `Either`
- [`Control.Monad.Trans.Except`](https://hackage.haskell.org/package/transformers/docs/Control-Monad-Trans-Except.html) — `ExceptT`, the transformer this library's `EitherT*`/`*TEither` stacks correspond to
