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
let mapped1 = { $0 * 2 } <£> Either<String, Int>.right(5)       // .right(10)
let mapped2 = { $0 * 2 } <£> Either<String, Int>.left("error")  // .left("error")

let mapped3 = Either<String, Int>.right(5) <&> { $0 * 2 }       // .right(10)
let mapped4 = Either<String, Int>.left("error") <&> { $0 * 2 }  // .left("error")

// Named function
let mapped5 = Either<String, Int>.fmap { $0 * 2 }(.right(5))  // .right(10)
let mapped6 = Either<String, Int>.right(5).mapRight { $0 * 2 }  // .right(10)
```

---

## `£>` and `<£` — Replace

Replace the right value with a constant. Left values pass through unchanged.

```swift
let replaced1 = Either<String, Int>.right(42) £> "done"    // .right("done")
let replaced2 = Either<String, Int>.left("err") £> "done"  // .left("err")

let replaced3 = "done" <£ Either<String, Int>.right(42)    // .right("done")
```

---

## `<*>` — Apply

Apply a function in an `Either` to a value in an `Either`. Both must be `.right`.

```swift
typealias Doubler = @Sendable (Int) -> Int
let double: Doubler = { $0 * 2 }

let applied1 = Either<String, Doubler>.right(double) <*> Either<String, Int>.right(5)       // .right(10)
let applied2 = Either<String, Doubler>.right(double) <*> Either<String, Int>.left("error")  // .left("error")
let applied3 = Either<String, Doubler>.left("no fn") <*> Either<String, Int>.right(5)       // .left("no fn")

// Named function
let applied4 = Either<String, Int>.apply(.right(double), .right(5))  // .right(10)
```

---

## `*>` and `<*` — Sequence

Run two eithers in sequence, keeping only one side's value. Any left propagates.

```swift
let seq1 = Either<String, Int>.right(1) *> Either<String, Int>.right(2)      // .right(2)
let seq2 = Either<String, Int>.left("err") *> Either<String, Int>.right(2)   // .left("err")
let seq3 = Either<String, Int>.right(1) *> Either<String, Int>.left("err")   // .left("err")

let seq4 = Either<String, Int>.right(1) <* Either<String, Int>.right(2)      // .right(1)
let seq5 = Either<String, Int>.right(1) <* Either<String, Int>.left("err")   // .left("err")

// Named functions
let seq6 = Either<String, Int>.right(1).seqRight(Either<String, Int>.right(2))  // .right(2)
let seq7 = Either<String, Int>.right(1).seqLeft(Either<String, Int>.right(2))   // .right(1)
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain operations that each may produce a left. `>>-` puts the container on the left; `-<<` puts the function on the left.

```swift
@Sendable func parse(_ s: String) -> Either<String, Int> {
    Int(s).map(Either<String, Int>.right) ?? .left("Not a number: \(s)")
}
@Sendable func validate(_ n: Int) -> Either<String, Int> {
    n > 0 ? .right(n) : .left("Must be positive: \(n)")
}

let bound1 = Either<String, String>.right("42") >>- parse >>- validate    // .right(42)
let bound2 = Either<String, String>.right("-1") >>- parse >>- validate    // .left("Must be positive: -1")
let bound3 = Either<String, String>.right("??") >>- parse                 // .left("Not a number: ??")

let bound4 = validate -<< Either<String, Int>.right(42)   // .right(42)
let bound5 = validate -<< Either<String, Int>.right(-1)   // .left("Must be positive: -1")

// Named function
let bound6 = Either<String, String>.right("42").flatMap(parse)  // .right(42)
let bound7 = Either<String, Int>.bind(validate)(.right(42))     // .right(42)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return an `Either`.

```swift
let pipeline = parse >=> validate
let piped1 = pipeline("42")   // .right(42)
let piped2 = pipeline("-1")   // .left("Must be positive: -1")
let piped3 = pipeline("??")   // .left("Not a number: ??")

// Named function
let piped4 = Either<String, Int>.kleisli(parse, validate)("42")  // .right(42)
```

---

## `<|>` — Alternative

Return the first `.right`, or the last `.left` if both fail.

```swift
let alt1 = Either<String, Int>.left("a") <|> .right(3)    // .right(3)
let alt2 = Either<String, Int>.right(1) <|> .right(3)     // .right(1)
let alt3 = Either<String, Int>.left("a") <|> .left("b")   // .left("b")
```

---

## Mapping both sides

`Either` supports mapping either side independently.

```swift
// mapLeft: transform the left (failure) side
let left1 = Either<String, Int>.left("error").mapLeft { $0.uppercased() }  // .left("ERROR")
let left2 = Either<String, Int>.right(42).mapLeft { $0.uppercased() }      // .right(42)

// bimap: transform both sides at once
let both1 = Either<String, Int>.right(42).bimap(
    { $0.uppercased() },
    { $0 * 2 }
)  // .right(84)

let both2 = Either<String, Int>.left("error").bimap(
    { $0.uppercased() },
    { $0 * 2 }
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

let eo: EitherTOptional<String, Int> = Either<String, Int?>.right(.some(5)).eitherT
let eoMapped = eo.map { $0 * 2 }.rawValue  // .right(Optional(10))
let eoBound = eo.flatMap { n in EitherTOptional<String, Int>(.right(.some(n * 2))) }.rawValue  // .right(Optional(10))

let eoNone = EitherTOptional<String, Int>(.right(.none))
let eoNothing = eoNone.flatMap { n in EitherTOptional<String, Int>(.right(.some(n * 2))) }.rawValue  // .right(nil), nothing to bind

let eoLeft = EitherTOptional<String, Int>(.left("err"))
let eoErr = eoLeft.flatMap { n in EitherTOptional<String, Int>(.right(.some(n * 2))) }.rawValue  // .left("err")

// Operators
let eoOp = ({ $0 * 2 } <£> eo).rawValue   // .right(Optional(10))
let eoChain = eo >>- { n in EitherTOptional<String, Int>.pure(n + 1) }   // EitherTOptional wrapping .right(Optional(6))
```

### `EitherTArray` (wraps `Either<L, [A]>`, outer = Either, inner = Array)

Either containing an Array. `.left` propagates; `.right(arr)` maps and combines elements.
Functor and Applicative only (the struct conforms to `TransformerStack`, not `MonadT`): there is no
lawful monad for a list inside a non-commutative outer layer (Haskell's old `ListT` problem), so
there is no `flatMap` / `>>-` for this stack.

```swift
import DataStructure

let ea = EitherTArray<String, Int>(.right([1, 2, 3]))
let eaMapped = ea.map { $0 * 2 }.rawValue  // .right([2, 4, 6])
let eaLifted = EitherTArray<String, Int>.liftA2(+)(ea, EitherTArray<String, Int>(.right([10, 20]))).rawValue  // .right([11, 21, 12, 22, 13, 23])

let eaErr = EitherTArray<String, Int>.liftA2(+)(EitherTArray<String, Int>(.left("err")), ea).rawValue  // .left("err")
```

### `EitherTResult` (wraps `Either<L, Result<A, E>>`, outer = Either, inner = Result)

Either containing a Result, two independent error channels. Generic order is `EitherTResult<L, E, A>`.

```swift
import DataStructure

enum MyError: Error, Sendable { case bad }

let er = EitherTResult<String, MyError, Int>(.right(.success(5)))
let erMapped = er.map { $0 * 2 }.rawValue  // .right(.success(10))
let erBound = er.flatMap { n in EitherTResult<String, MyError, Int>(.right(.success(n * 2))) }.rawValue  // .right(.success(10))

// Inner failure preserves outer .right
let innerFail = EitherTResult<String, MyError, Int>(.right(.failure(.bad)))
let innerKept = innerFail.flatMap { n in EitherTResult<String, MyError, Int>.pure(n) }.rawValue  // .right(.failure(.bad))
```

### `OptionalTEither` (wraps `Either<L, A>?`, outer = Optional, inner = Either)

Optional wrapping an Either. `nil` propagates; `.some(.left(l))` also propagates.

```swift
import DataStructure

let oe: OptionalTEither<String, Int> = Optional(Either<String, Int>.right(5)).optionalT
let oeMapped = oe.map { $0 * 2 }.rawValue                                            // Optional(.right(10))
let oeBound = oe.flatMap { n in OptionalTEither<String, Int>(.right(n * 2)) }.rawValue  // Optional(.right(10))

let oeNil = OptionalTEither<String, Int>(nil).map { $0 * 2 }.rawValue   // nil

let oeLeft = OptionalTEither<String, Int>(.left("err"))
let oeErr = oeLeft.map { $0 * 2 }.rawValue                              // Optional(.left("err"))
```

### `ArrayTEither` (wraps `[Either<L, A>]`, outer = Array, inner = Either)

Array of Either values. `.left` elements propagate; `.right` elements are transformed.

```swift
import DataStructure

let es: [Either<String, Int>] = [.right(1), .left("err"), .right(3)]
let esMapped = es.arrayT.map { $0 * 2 }.rawValue  // [.right(2), .left("err"), .right(6)]
let esBound = es.arrayT.flatMap { n in ArrayTEither<String, Int>([.right(n), .right(n * 10)]) }.rawValue
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
