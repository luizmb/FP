# ``Swift/Result``

Swift's `Result<Success, Failure>` extended with functional operators and named functions.

A `Result` is either `.success(value)` or `.failure(error)`. The operators let you transform and chain results without manual `switch` statements.

---

## `<£>` and `<&>` — Map

Apply a function to the success value. `<£>` puts the function on the left; `<&>` puts the result on the left.

```swift
// The examples in this article share these definitions.
enum MyError: Error, Equatable {
    case invalidInput
    case outOfRange
    case bad
    case a
    case b
}

let err = MyError.bad

_ = { $0 * 2 } <£> Result<Int, MyError>.success(5)   // .success(10)
_ = { $0 * 2 } <£> Result<Int, MyError>.failure(err) // .failure(err)

_ = Result<Int, MyError>.success(5) <&> { $0 * 2 }   // .success(10)
_ = Result<Int, MyError>.failure(err) <&> { $0 * 2 } // .failure(err)

// Named function
_ = Result<Int, MyError>.fmap { $0 * 2 }(.success(5))  // .success(10)
_ = Result<Int, MyError>.success(5).map { $0 * 2 }     // .success(10)
```

---

## `£>` and `<£` — Replace

Replace the success value with a constant. Failures pass through unchanged.

```swift
_ = Result<Int, MyError>.success(42) £> "done"   // .success("done")
_ = Result<Int, MyError>.failure(err) £> "done"  // .failure(err)

_ = "done" <£ Result<Int, MyError>.success(42)   // .success("done")

// Named function
_ = Result<Int, MyError>.fmap(const("done"))(.success(42))  // .success("done")
```

---

## `<*>` — Apply

Apply a function wrapped in a `Result` to a value wrapped in a `Result`. Both must be `.success`.

```swift
let double: Result<@Sendable (Int) -> Int, MyError> = .success({ $0 * 2 })
let noFunction: Result<@Sendable (Int) -> Int, MyError> = .failure(err)

_ = double <*> .success(5)       // .success(10)
_ = double <*> .failure(err)     // .failure(err)
_ = noFunction <*> .success(5)   // .failure(err)

// Named function
_ = Result<Int, MyError>.apply(double, .success(5))  // .success(10)
```

---

## `*>` and `<*` — Sequence

Run two results in sequence, keeping only one side's value. If either fails, the failure propagates.

```swift
_ = Result<String, MyError>.success("a") *> Result<String, MyError>.success("b")   // .success("b")
_ = Result<String, MyError>.failure(err) *> Result<String, MyError>.success("b")   // .failure(err)
_ = Result<String, MyError>.success("a") *> Result<String, MyError>.failure(err)   // .failure(err)

_ = Result<String, MyError>.success("a") <* Result<String, MyError>.success("b")   // .success("a")
_ = Result<String, MyError>.success("a") <* Result<String, MyError>.failure(err)   // .failure(err)

// Named functions
_ = Result<String, MyError>.success("a").seqRight(.success("b"))  // .success("b")
_ = Result<String, MyError>.success("a").seqLeft(.success("b"))   // .success("a")
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain operations that each may fail. `>>-` puts the container on the left; `-<<` puts the function on the left.

```swift
@Sendable func parse(_ s: String) -> Result<Int, MyError> {
    Int(s).map(Result.success) ?? .failure(.invalidInput)
}
@Sendable func validate(_ n: Int) -> Result<Int, MyError> {
    n > 0 ? .success(n) : .failure(.outOfRange)
}

_ = Result<String, MyError>.success("42") >>- parse >>- validate  // .success(42)
_ = Result<String, MyError>.success("-1") >>- parse >>- validate  // .failure(.outOfRange)
_ = Result<String, MyError>.success("??") >>- parse               // .failure(.invalidInput)

_ = validate -<< Result<Int, MyError>.success(42)   // .success(42)
_ = validate -<< Result<Int, MyError>.success(-1)   // .failure(.outOfRange)

// Named function
_ = Result<Int, MyError>.bind(validate)(.success(42))  // .success(42)
_ = Result<Int, MyError>.success(42).flatMap(validate) // .success(42)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Result`, producing a single function.

```swift
// parse and validate are the functions from the bind section.
@Sendable func doubled(_ n: Int) -> Result<Int, MyError> { .success(n * 2) }

let pipeline = parse >=> validate >=> doubled
_ = pipeline("21")   // .success(42)
_ = pipeline("-1")   // .failure(.outOfRange), fails at validate
_ = pipeline("??")   // .failure(.invalidInput), fails at parse

// Named function
_ = Result<Int, MyError>.kleisli(parse, validate)("21")  // .success(21)
```

---

## `<|>` — Alternative

Return the first `.success`, or the last `.failure` if both fail.

```swift
_ = Result<Int, MyError>.failure(.a) <|> .success(3)   // .success(3)
_ = Result<Int, MyError>.success(1) <|> .success(3)    // .success(1)
_ = Result<Int, MyError>.failure(.a) <|> .failure(.b)  // .failure(.b)
```

---

## Traverse

Useful for **inverting nested structures** — turning an array of results into a single result wrapping an array, or an optional result inside-out.

```swift
// sequence :: [Result<a,e>] -> Result<[a],e>   — Array<Result> into Result<Array>
// All must succeed; stops at the first failure
[Result<Int, MyError>.success(1), .success(2), .success(3)].sequence()
// .success([1, 2, 3])

[Result<Int, MyError>.success(1), .failure(.outOfRange), .success(3)].sequence()
// .failure(.outOfRange)

// traverse :: (a -> Result<b,e>) -> [a] -> Result<[b],e>
["1", "2", "3"].traverse(parse)   // .success([1, 2, 3])
["1", "??", "3"].traverse(parse)  // .failure(.invalidInput)

// sequence :: Result<a,e>? -> Result<a?,e>   — Optional<Result> into Result<Optional>
Optional(Result<Int, MyError>.success(42)).sequence()  // .success(Optional(42))
(nil as Result<Int, MyError>?).sequence()              // .success(nil)
```

---

## `Result.Monoids` — combining strategies

`Result` can't have a single `Semigroup` instance because it's not obvious what "combine two results" should mean. This library offers four explicit strategies as nested wrapper types: each one wraps a `Result` (`Optimistic(.success(1))`, read it back with `.rawValue`) and conforms to `Semigroup` (and `Monoid` for the two `Combining` variants).

The examples below use a failure type that accumulates, because `Result` requires its `Failure` to be an `Error` and arrays are not.

```swift
struct Errors: Error, Equatable, Semigroup, Monoid {
    var all: [MyError]

    static func combine(_ lhs: Errors, _ rhs: Errors) -> Errors { Errors(all: lhs.all + rhs.all) }
    static var identity: Errors { Errors(all: []) }
}

typealias Ints = Result<[Int], Errors>
typealias Lists = Result<[Int], MyError>
```

### `Optimistic`: success wins

If either value is `.success`, the result is `.success`. Combining two successes requires `Success: Semigroup`. If both fail, the left failure is kept.

```swift
// Success wins over failure
_ = Lists.Monoids.Optimistic.combine(.init(.success([1])), .init(.failure(.bad)))   // .success([1])
_ = Lists.Monoids.Optimistic.combine(.init(.failure(.bad)), .init(.success([2])))   // .success([2])

// Two successes are combined
_ = Lists.Monoids.Optimistic.combine(.init(.success([1, 2])), .init(.success([3, 4])))
// .success([1, 2, 3, 4])
```

### `OptimisticCombining`: success wins, with identity

Same as `Optimistic`, except two failures are combined as well, and it is a `Monoid`. Requires `Success: Semigroup` and `Failure: Monoid`. The identity element is `.failure(Failure.identity)`.

```swift
_ = Ints.Monoids.OptimisticCombining.identity
// .failure(Errors(all: []))

_ = Ints.Monoids.OptimisticCombining.combine(.init(.success([1])), .init(.success([2])))
// .success([1, 2])

_ = Ints.Monoids.OptimisticCombining.combine(
    .init(.failure(Errors(all: [.a]))),
    .init(.failure(Errors(all: [.b])))
)
// .failure(Errors(all: [.a, .b]))
```

### `Pessimistic`: failure wins

If either value is `.failure`, the result is `.failure`. Combining two failures requires `Failure: Semigroup`. Two successes keep the left one (no `Semigroup` is required for the success).

```swift
_ = Ints.Monoids.Pessimistic.combine(.init(.success([1])), .init(.failure(Errors(all: [.bad]))))
// .failure(Errors(all: [.bad]))

_ = Ints.Monoids.Pessimistic.combine(
    .init(.failure(Errors(all: [.a]))),
    .init(.failure(Errors(all: [.b])))
)
// .failure(Errors(all: [.a, .b]))

// Two successes: the left one wins
_ = Ints.Monoids.Pessimistic.combine(.init(.success([1])), .init(.success([2])))   // .success([1])
```

### `PessimisticCombining`: failure wins, with identity

Same as `Pessimistic`, except two successes are combined as well. Requires `Success: Semigroup` and `Failure: Semigroup`, and it is a `Monoid` when `Success: Monoid`. The identity element is `.success(Success.identity)`.

```swift
_ = Ints.Monoids.PessimisticCombining.identity
// .success([])

_ = Ints.Monoids.PessimisticCombining.combine(.init(.success([1])), .init(.success([2])))
// .success([1, 2])

_ = Ints.Monoids.PessimisticCombining.combine(
    .init(.failure(Errors(all: [.a]))),
    .init(.failure(Errors(all: [.b])))
)
// .failure(Errors(all: [.a, .b]))
```

### Choosing a strategy

| Strategy | Success + Success | Success + Failure | Failure + Failure |
|---|---|---|---|
| `Optimistic` | combine (requires `Success: Semigroup`) | success wins | left failure |
| `OptimisticCombining` | combine | success wins | combine (requires `Failure: Semigroup`) |
| `Pessimistic` | left success | failure wins | combine (requires `Failure: Semigroup`) |
| `PessimisticCombining` | combine | failure wins | combine |

Use `Optimistic` when partial success is acceptable. Use `Pessimistic` for validation pipelines where any failure must propagate.

---

## `bimap` — transform both sides

Transform the success and failure values simultaneously:

```swift
let result: Result<Int, MyError> = .failure(.outOfRange)

_ = result.bimap(
    { $0 * 2 },          // success path
    { Errors(all: [$0]) } // failure path
)
// .failure(Errors(all: [.outOfRange]))

_ = Result<Int, MyError>.success(21).bimap({ $0 * 2 }, { Errors(all: [$0]) })
// .success(42)
```

---

## Module

```swift
import FP       // Named functions (fmap, apply, seqRight, bind, kleisli…)
import CoreFPOperators // Operators (<£>, <*>, >>-, >=>…)
```

---

## For Haskell developers

Swift's `Result<Success, Failure>` has **no direct Haskell equivalent**. Haskell doesn't need a separate "result" type because `Either`'s two sides aren't semantically pinned to error/success — `Either e a` already fills this role, with `Left`/`Right` standing in for whatever convention the code adopts (usually `Left` = error). This library exists because Swift's standard library ships `Result` as a distinct, `Error`-constrained type; the functional idioms below are exactly what Haskell developers get "for free" from `Either`'s `Functor`/`Applicative`/`Monad` instances.

| This library | Haskell equivalent |
|---|---|
| `Result<Success, Failure>` | no dedicated type — `Either e a` fills this role (`Left`/`Right` in place of `.failure`/`.success`) |
| `<£>` / `<&>` (`fmap`) | `fmap` / `<$>` on `Either e` (maps the `Right`/success side) |
| `bimap` | `Data.Bifunctor`'s `bimap` |
| `<*>` | `Applicative`'s `<*>` |
| `>>-` / `-<<` (`flatMap`) | `>>=` / `=<<` |
| `>=>` | `Control.Monad`'s `>=>` |
| `<|>` | not in `base` for `Either` — same caveat as `Either`'s article |
| `sequence` / `traverse` | `Data.Traversable`'s `sequence` / `traverse`, specialised to `[Either e a]` or `Maybe (Either e a)` |
| `Result.Monoids.{Optimistic,Pessimistic,…}` | no bespoke equivalent — a Haskell developer would reach for `newtype` wrappers over `Either` with hand-written `Semigroup`/`Monoid` instances to get the same "success wins" / "failure wins" choice |

External references:
- [`Data.Either`](https://hackage.haskell.org/package/base/docs/Data-Either.html) — the type this library's idioms are modeled after
- [`Control.Monad.Trans.Except`](https://hackage.haskell.org/package/transformers/docs/Control-Monad-Trans-Except.html) — `ExceptT`, Haskell's error-handling transformer built on `Either`
