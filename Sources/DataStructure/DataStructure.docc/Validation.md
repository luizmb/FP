# ``Validation``

`Validation<E: Semigroup, A>` is a type with exactly two cases: `.failure(E)` or `.success(A)`.

It solves the same problem as `Result` (representing success or failure) but with a critical difference: **errors accumulate**. When you combine two failing validations, you get all the errors, not just the first one. This makes it ideal for form validation, config parsing, or any scenario where you want to report every problem at once rather than stopping at the first.

The error type `E` must be a `Semigroup` so the library knows how to combine multiple errors together (typically `[String]` or a custom enum array).

```swift
import DataStructure

func validateName(_ s: String) -> Validation<[String], String> {
    s.isEmpty ? .failure(["Name is required"]) : .success(s)
}
func validateAge(_ n: Int) -> Validation<[String], Int> {
    n < 0 ? .failure(["Age must be non-negative"]) : .success(n)
}
```

---

## `<£>` and `<&>` — Map

Apply a function to the success value. Failures pass through unchanged.

```swift
let upper1 = { $0.uppercased() } <£> Validation<[String], String>.success("alice")  // .success("ALICE")
let upper2 = { $0.uppercased() } <£> Validation<[String], String>.failure(["err"])  // .failure(["err"])

let upper3 = Validation<[String], String>.success("alice") <&> { $0.uppercased() }  // .success("ALICE")

// Named functions
let upper4 = Validation<[String], String>.success("alice").mapSuccess { $0.uppercased() }
let upper5 = Validation<[String], String>.fmap { $0.uppercased() }(.success("alice"))
```

---

## `£>` and `<£` — Replace

Replace the success value with a constant. Failures pass through unchanged.

```swift
let done1 = Validation<[String], Int>.success(42) £> "done"       // .success("done")
let done2 = Validation<[String], Int>.failure(["err"]) £> "done"  // .failure(["err"])

let done3 = "done" <£ Validation<[String], Int>.success(42)       // .success("done")
```

---

## `<*>` — Apply (with error accumulation)

This is where `Validation` shines. Unlike `Result`, when **both** sides fail, both sets of errors are combined using `Semigroup.combine`:

```swift
struct User: Sendable {
    let name: String
    let age: Int
}

typealias UserBuilder = @Sendable (String) -> @Sendable (Int) -> User
let makeUser: UserBuilder = { name in { age in User(name: name, age: age) } }

let nameResult: Validation<[String], String> = validateName("")
let ageResult: Validation<[String], Int> = validateAge(-5)

// Build a User only if both succeed; collect ALL errors if any fail
let bothFail = Validation<[String], UserBuilder>.success(makeUser)
    <*> nameResult
    <*> ageResult
// .failure(["Name is required", "Age must be non-negative"])
//           ^^^ both errors collected, not just the first

// If only one fails:
let oneFails = Validation<[String], UserBuilder>.success(makeUser)
    <*> validateName("Alice")
    <*> validateAge(-5)
// .failure(["Age must be non-negative"])

// If both succeed:
let bothSucceed = Validation<[String], UserBuilder>.success(makeUser)
    <*> validateName("Alice")
    <*> validateAge(30)
// .success(User(name: "Alice", age: 30))

// Named function
let doubler: @Sendable (Int) -> Int = { $0 * 2 }
let applied = Validation<[String], Int>.apply(.success(doubler), .success(21))  // .success(42)
let zipped = Validation<[String], (String, Int)>.zip(validateName("Alice"), validateAge(30))  // .success(("Alice", 30))
let lifted = Validation<[String], User>.liftA2 { User(name: $0, age: $1) }(validateName("Alice"), validateAge(30))  // .success(User(...))
```

> **Why no `flatMap`?** `flatMap` is inherently sequential — the second step can't start until the first succeeds. Accumulating errors requires running all validations *independently* and then combining, which is exactly what `<*>` and `zip` do. `Validation` is an Applicative, not a Monad.

---

## `*>` and `<*` — Sequence

Run two validations, accumulating errors from both, keeping only one result.

```swift
let seq1 = validateName("Alice") *> validateAge(30)   // .success(30)
let seq2 = validateName("") *> validateAge(-1)        // .failure(["Name is required", "Age must be non-negative"])
let seq3 = validateName("") *> validateAge(30)        // .failure(["Name is required"])

let seq4 = validateName("Alice") <* validateAge(30)   // .success("Alice")

// Named functions
let seq5 = validateName("Alice").seqRight(validateAge(30))  // .success(30)
let seq6 = validateName("Alice").seqLeft(validateAge(30))   // .success("Alice")
```

---

## `<|>` — Alt

Return the first success; when both fail, the errors accumulate (Haskell's `Alt (Validation e)`). The right side is only evaluated when the left fails. There's no `empty`, so this is `Alt`, not `Alternative`.

```swift
let alt1 = Validation<[String], Int>.failure(["a"]) <|> .success(3)          // .success(3)
let alt2 = Validation<[String], Int>.success(1) <|> .success(3)             // .success(1)
let alt3 = Validation<[String], Int>.failure(["a"]) <|> .failure(["b"])     // .failure(["a", "b"])
```

---

## Mapping both sides

```swift
// mapFailure: transform the error type
let shouted = Validation<[String], Int>.failure(["oops"]).mapFailure { $0.map { $0.uppercased() } }
// .failure(["OOPS"])

// bimap: transform both sides at once
let bimapped1 = Validation<[String], Int>.success(42).bimap(
    { $0.map { "Error: \($0)" } },  // failure path
    { $0 * 2 }                       // success path
)  // .success(84)

let bimapped2 = Validation<[String], Int>.failure(["oops"]).bimap(
    { $0.map { "Error: \($0)" } },
    { $0 * 2 }
)  // .failure(["Error: oops"])
```

---

## Foldable

```swift
let folded1 = Validation<[String], Int>.success(5).foldMap { Int.Monoids.Sum($0) }       // Sum(5)
let folded2 = Validation<[String], Int>.failure(["e"]).foldMap { Int.Monoids.Sum($0) }   // Sum(0), the identity

let list1 = Validation<[String], Int>.success(42).toList    // [42]
let list2 = Validation<[String], Int>.failure(["e"]).toList // []
```

---

## Conversions

```swift
// toEither: right is success, left is failure
let either1 = Validation<[String], Int>.success(42).toEither()     // .right(42)
let either2 = Validation<[String], Int>.failure(["e"]).toEither()  // .left(["e"])

// toResult requires E: Error
struct MyError: Error, Semigroup, Sendable {
    static func combine(_ lhs: MyError, _ rhs: MyError) -> MyError { lhs }
}

let result1 = Validation<MyError, Int>.success(42).toResult()      // .success(42)
let result2 = Validation<MyError, Int>.failure(MyError()).toResult()    // .failure(MyError())

// From Either / Result
let from1 = Validation<[String], Int>(Either<[String], Int>.right(42))  // .success(42)
let from2 = Validation<MyError, Int>(Result<Int, MyError>.success(42))  // .success(42), requires E: Semigroup & Error
let from3 = Either<[String], Int>.right(42).toValidation()  // .success(42)
```

---

## Traversable

`Validation` is Traversable when its success type is a container. These operations "flip" the nesting.

```swift
// sequence: Validation<E, [A]> -> [Validation<E, A>]
let seqA = Validation<[String], [Int]>.success([1, 2, 3]).sequence()   // [.success(1), .success(2), .success(3)]
let seqB = Validation<[String], [Int]>.failure(["e"]).sequence()       // [.failure(["e"])]

// Using traverse
let trav1 = Validation<[String], String>.success("42").traverse { Int($0) }   // Optional(.success(42))
let trav2 = Validation<[String], String>.success("xx").traverse { Int($0) }   // nil

// sequence: Validation<E, Result<A, Err>> -> Result<Validation<E, A>, Err>
let seqC = Validation<[String], Result<Int, MyError>>.success(.success(5)).sequence()
// .success(.success(5)), or propagates failure from either layer
```

---

## Monad Transformers

Validation is the **outer** layer of eight stacks (`ValidationTArray`, `ValidationTOptional`, `ValidationTResult`, `ValidationTEither`, `ValidationTReader`, `ValidationTStateful`, `ValidationTWriter`, `ValidationTNonEmpty`) and the **inner** layer of `EitherTValidation`, `ReaderTValidation`, `StatefulTValidation` and `WriterTValidation`. Each stack is its own struct around the nested value: lift in with `validation.validationT` (or the stack's `init(_:)`), use `map` / `apply` / `liftA2` / the operators, and leave with `.rawValue`. Since Validation has no monad, none of these stacks has `flatMap` (they conform to `TransformerStack`, not `MonadT`).

### `ValidationTOptional` (wraps `Validation<E, A?>`, outer = Validation, inner = Optional)

```swift
let vOpt: Validation<[String], Int?> = .success(.some(5))

// map reaches inside the Optional without touching the Validation layer
let vOptMapped = vOpt.validationT.map { $0 * 2 }.rawValue  // .success(Optional(10))

let vNone: Validation<[String], Int?> = .success(.none)
let vNoneMapped = vNone.validationT.map { $0 * 2 }.rawValue  // .success(nil)

let vFailed: Validation<[String], Int?> = .failure(["e"])
let vFailedMapped = vFailed.validationT.map { $0 * 2 }.rawValue  // .failure(["e"])
```

### `ValidationTArray` (wraps `Validation<E, [A]>`, outer = Validation, inner = Array)

```swift
let vArr = ValidationTArray<[String], Int>(.success([1, 2, 3]))
let vArrMapped = vArr.map { $0 * 2 }.rawValue  // .success([2, 4, 6])
```

### `ValidationTResult` (wraps `Validation<E, Result<A, Err>>`, outer = Validation, inner = Result)

Generic order is `ValidationTResult<E, Err, A>`.

```swift
let vRes = ValidationTResult<[String], MyError, Int>(.success(.success(5)))
let vResMapped = vRes.map { $0 * 2 }.rawValue  // .success(.success(10))

// Inner failure passes through the outer success
let innerFail = ValidationTResult<[String], MyError, Int>(.success(.failure(MyError())))
let innerKept = innerFail.map { $0 * 2 }.rawValue  // .success(.failure(MyError()))
```

### `Validation<E, A>?` and `[Validation<E, A>]`

There are no `OptionalTValidation` / `ArrayTValidation` stacks; map the outer container and the Validation in turn:

```swift
let maybeV: Validation<[String], Int>? = .success(5)
let maybeDoubled = maybeV.map { $0.mapSuccess { $0 * 2 } }   // Optional(.success(10))

let vs: [Validation<[String], Int>] = [.success(1), .failure(["e"]), .success(3)]
let vsDoubled = vs.map { $0.mapSuccess { $0 * 2 } }  // [.success(2), .failure(["e"]), .success(6)]
```

Escape hatches (the whole nested value in, a new nested value out) follow Haskell's names:
`mapMaybeT` on `ValidationTOptional`, `mapExceptT` on `ValidationTResult` / `ValidationTEither`,
`mapWriterT` on `ValidationTWriter`, and `mapValidationT` on the other Validation-outer stacks.

---

## Module

```swift
import DataStructure         // Validation type, named functions and the ValidationT* stack structs
import DataStructureOperators // Operators (<£>, <*>, *>, <*…), also for the stacks
```

---

## For Haskell developers

| This library | Haskell equivalent |
|---|---|
| `Validation<E: Semigroup, A>` | the [`validation`](https://hackage.haskell.org/package/validation) package's `Validation e a` (`Data.Validation`) |
| `.failure` / `.success` | `Failure` / `Success` |
| `<£>` / `<&>` (`fmap`) | `fmap` / `<$>` |
| `<*>` (error-accumulating apply) | `Data.Validation`'s `<*>` — accumulates via the `Semigroup e` constraint, identically to this library |
| `bimap` | `Data.Bifunctor`'s `bimap` |
| `mapFailure` | `Data.Bifunctor`'s `first` |
| `toEither` | `Data.Validation`'s `toEither` |
| `Validation(_ either:)` | `Data.Validation`'s `fromEither` |
| `sequence` / `traverse` (Traversable) | `Data.Traversable`'s `sequence` / `traverse` |

Haskell's `Validation` is, for the exact same reason as this library's, **Applicative but not Monad** — accumulating every error requires running both sides independently, which is incompatible with `flatMap`'s inherently sequential, short-circuiting nature. This is a rare case where the Swift and Haskell libraries independently arrived at the identical design constraint, rather than one copying the other.

External references:
- [`Data.Validation`](https://hackage.haskell.org/package/validation/docs/Data-Validation.html) — the `validation` package this type mirrors
- McBride & Paterson, ["Applicative Programming with Effects"](http://www.staff.city.ac.uk/~ross/papers/Applicative.html) — the paper formalising the Applicative abstraction that makes accumulating validation possible without a Monad
