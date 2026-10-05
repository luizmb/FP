# ``Either``

`Either<Left, Right>` is a type with exactly two possible cases: `.left(Left)` or `.right(Right)`.

It solves the same problem as `Result` — representing success or failure — but without requiring the error type to conform to `Error`. By convention the right side is the "happy path" and the left is the failure, but both sides are equal citizens and can hold any type. This makes `Either` more flexible when your error type is a simple enum, a `String`, or any non-`Error` type.

```swift
import DataStructure

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

Either participates in transformer stacks in two ways: as the **outer** layer (`EitherT{Inner}`) or as the **inner** layer (`{Outer}TEither`). Each stack is its own struct wrapping the nested value: lift a nested value in with the property on the outer type (`either.eitherT`, `optional.optionalT`, `array.arrayT`) or the stack's `init(_:)`, use `map` / `flatMap` / `apply` / `liftA2` or the operators, and leave with `.rawValue`. A bare `Either<L, A?>` is still just an `Either`, so its own `map` and `<£>` see the whole `A?`.

### `EitherTOptional` (wraps `Either<L, A?>`, outer = Either, inner = Optional)

Either containing an Optional. `.left` propagates; `.right(.none)` stays `.right(.none)`.

```swift
import DataStructure
import DataStructureOperators

let e: EitherTOptional<String, Int> = Either<String, Int?>.right(.some(5)).eitherT
e.map { $0 * 2 }.rawValue  // .right(Optional(10))
e.flatMap { n in EitherTOptional(.right(.some(n * 2))) }.rawValue  // .right(Optional(10))

let none = EitherTOptional<String, Int>(.right(.none))
none.flatMap { n in EitherTOptional(.right(.some(n * 2))) }.rawValue  // .right(nil), nothing to bind

let left = EitherTOptional<String, Int>(.left("err"))
left.flatMap { n in EitherTOptional(.right(.some(n * 2))) }.rawValue  // .left("err")

// Operators
({ $0 * 2 } <£> e).rawValue   // .right(Optional(10))
e >>- { n in .pure(n + 1) }    // EitherTOptional wrapping .right(Optional(6))
```

### `EitherTArray` (wraps `Either<L, [A]>`, outer = Either, inner = Array)

Either containing an Array. `.left` propagates; `.right(arr)` maps and combines elements.
Functor and Applicative only (the struct conforms to `TransformerStack`, not `MonadT`): there is no
lawful monad for a list inside a non-commutative outer layer (Haskell's old `ListT` problem), so
there is no `flatMap` / `>>-` for this stack.

```swift
import DataStructure

let e = EitherTArray<String, Int>(.right([1, 2, 3]))
e.map { $0 * 2 }.rawValue  // .right([2, 4, 6])
EitherTArray.liftA2(+)(e, EitherTArray(.right([10, 20]))).rawValue  // .right([11, 21, 12, 22, 13, 23])

EitherTArray.liftA2(+)(EitherTArray<String, Int>(.left("err")), e).rawValue  // .left("err")
```

### `EitherTResult` (wraps `Either<L, Result<A, E>>`, outer = Either, inner = Result)

Either containing a Result, two independent error channels. Generic order is `EitherTResult<L, E, A>`.

```swift
import DataStructure

let e = EitherTResult<String, MyError, Int>(.right(.success(5)))
e.map { $0 * 2 }.rawValue  // .right(.success(10))
e.flatMap { n in EitherTResult(.right(.success(n * 2))) }.rawValue  // .right(.success(10))

// Inner failure preserves outer .right
let innerFail = EitherTResult<String, MyError, Int>(.right(.failure(.bad)))
innerFail.flatMap { n in .pure(n) }.rawValue  // .right(.failure(.bad))
```

### `OptionalTEither` (wraps `Either<L, A>?`, outer = Optional, inner = Either)

Optional wrapping an Either. `nil` propagates; `.some(.left(l))` also propagates.

```swift
import DataStructure

let e: OptionalTEither<String, Int> = Optional(Either<String, Int>.right(5)).optionalT
e.map { $0 * 2 }.rawValue                               // Optional(.right(10))
e.flatMap { n in OptionalTEither(.right(n * 2)) }.rawValue  // Optional(.right(10))

OptionalTEither<String, Int>(nil).map { $0 * 2 }.rawValue   // nil

let left = OptionalTEither<String, Int>(.left("err"))
left.map { $0 * 2 }.rawValue                            // Optional(.left("err"))
```

### `ArrayTEither` (wraps `[Either<L, A>]`, outer = Array, inner = Either)

Array of Either values. `.left` elements propagate; `.right` elements are transformed.

```swift
import DataStructure

let es: [Either<String, Int>] = [.right(1), .left("err"), .right(3)]
es.arrayT.map { $0 * 2 }.rawValue              // [.right(2), .left("err"), .right(6)]
es.arrayT.flatMap { n in ArrayTEither([.right(n), .right(n * 10)]) }.rawValue
// [.right(1), .right(10), .left("err"), .right(3), .right(30)]
```

Each stack also has an escape hatch that hands you the whole nested value, named after Haskell:
`mapMaybeT` on `EitherTOptional`, `mapExceptT` on `EitherTResult` / `OptionalTEither` /
`ArrayTEither`, and `mapEitherT` on Compose-like stacks such as `EitherTArray`.

---

## Module

```swift
import DataStructure          // Either type, named functions and the EitherT* / *TEither stack structs
import DataStructureOperators // Operators (<£>, <*>, >>-, >=>…) for Either and those stacks
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
