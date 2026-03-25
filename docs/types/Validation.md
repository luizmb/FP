# Validation

`Validation<E: Semigroup, A>` is a type with exactly two cases: `.failure(E)` or `.success(A)`.

It solves the same problem as `Result` — representing success or failure — but with a critical difference: **errors accumulate**. When you combine two failing validations, you get all the errors, not just the first one. This makes it ideal for form validation, config parsing, or any scenario where you want to report every problem at once rather than stopping at the first.

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
{ $0.uppercased() } <£> Validation<[String], String>.success("alice")  // .success("ALICE")
{ $0.uppercased() } <£> Validation<[String], String>.failure(["err"])  // .failure(["err"])

Validation.success("alice") <&> { $0.uppercased() }  // .success("ALICE")

// Named functions
Validation.success("alice").mapSuccess { $0.uppercased() }
Validation.fmap { $0.uppercased() }(.success("alice"))
```

---

## `£>` and `<£` — Replace

Replace the success value with a constant. Failures pass through unchanged.

```swift
Validation<[String], Int>.success(42) £> "done"    // .success("done")
Validation<[String], Int>.failure(["err"]) £> "done"  // .failure(["err"])

"done" <£ Validation<[String], Int>.success(42)    // .success("done")
```

---

## `<*>` — Apply (with error accumulation)

This is where `Validation` shines. Unlike `Result`, when **both** sides fail, both sets of errors are combined using `Semigroup.combine`:

```swift
let nameResult: Validation<[String], String> = validateName("")
let ageResult:  Validation<[String], Int>    = validateAge(-5)

// Build a User only if both succeed; collect ALL errors if any fail
Validation<[String], (String) -> (Int) -> User>.success(User.init)
    <*> nameResult
    <*> ageResult
// .failure(["Name is required", "Age must be non-negative"])
//           ^^^ both errors collected, not just the first

// If only one fails:
Validation<[String], (String) -> (Int) -> User>.success(User.init)
    <*> validateName("Alice")
    <*> validateAge(-5)
// .failure(["Age must be non-negative"])

// If both succeed:
Validation<[String], (String) -> (Int) -> User>.success(User.init)
    <*> validateName("Alice")
    <*> validateAge(30)
// .success(User(name: "Alice", age: 30))

// Named function
Validation.apply(.success({ $0 * 2 }), .success(21))  // .success(42)
Validation.zip(validateName("Alice"), validateAge(30)) // .success(("Alice", 30))
Validation.liftA2(User.init)(validateName("Alice"), validateAge(30))  // .success(User(...))
```

> **Why no `flatMap`?** `flatMap` is inherently sequential — the second step can't start until the first succeeds. Accumulating errors requires running all validations *independently* and then combining, which is exactly what `<*>` and `zip` do. `Validation` is an Applicative, not a Monad.

---

## `*>` and `<*` — Sequence

Run two validations, accumulating errors from both, keeping only one result.

```swift
validateName("Alice") *> validateAge(30)   // .success(30)
validateName("") *> validateAge(-1)        // .failure(["Name is required", "Age must be non-negative"])
validateName("") *> validateAge(30)        // .failure(["Name is required"])

validateName("Alice") <* validateAge(30)   // .success("Alice")

// Named functions
validateName("Alice").seqRight(validateAge(30))  // .success(30)
validateName("Alice").seqLeft(validateAge(30))   // .success("Alice")
```

---

## `<|>` — Alternative

Return the first success, or the last failure if both fail.

```swift
Validation<[String], Int>.failure(["a"]) <|> .success(3)    // .success(3)
Validation<[String], Int>.success(1)     <|> .success(3)    // .success(1)
Validation<[String], Int>.failure(["a"]) <|> .failure(["b"]) // .failure(["b"])
```

---

## Mapping both sides

```swift
// mapFailure — transform the error type
Validation<[String], Int>.failure(["oops"]).mapFailure { $0.map { $0.uppercased() } }
// .failure(["OOPS"])

// bimap — transform both sides at once
Validation<[String], Int>.success(42).bimap(
    { $0.map { "Error: \($0)" } },  // failure path
    { $0 * 2 }                       // success path
)  // .success(84)

Validation<[String], Int>.failure(["oops"]).bimap(
    { $0.map { "Error: \($0)" } },
    { $0 * 2 }
)  // .failure(["Error: oops"])
```

---

## Foldable

```swift
Validation<[String], Int>.success(5).foldMap { Sum($0) }   // Sum(5)
Validation<[String], Int>.failure(["e"]).foldMap { Sum($0) }  // Sum(0) — identity

Validation.success(42).toList    // [42]
Validation.failure(["e"]).toList // []
```

---

## Conversions

```swift
// toEither — right is success, left is failure
Validation<[String], Int>.success(42).toEither()     // .right(42)
Validation<[String], Int>.failure(["e"]).toEither()  // .left(["e"])

// toResult — requires E: Error
Validation<MyError, Int>.success(42).toResult()      // .success(42)
Validation<MyError, Int>.failure(.bad).toResult()    // .failure(.bad)

// From Either / Result
validationFromEither(Either<[String], Int>.right(42))  // .success(42)
```

---

## Traversable

`Validation` is Traversable when its success type is a container. These operations "flip" the nesting.

```swift
// ValidationTArray — Validation<E, [A]> → [Validation<E, A>]
Validation<[String], [Int]>.success([1, 2, 3]).sequence()   // [.success(1), .success(2), .success(3)]
Validation<[String], [Int]>.failure(["e"]).sequence()       // [.failure(["e"])]

// Using traverse
Validation.success("42").traverse { Int($0) }   // Optional(.success(42))
Validation.success("xx").traverse { Int($0) }   // nil

// ValidationTResult — Validation<E, Result<A,Err>>
Validation<[String], Result<Int, MyError>>.success(.success(5)).sequence()
// .success(.success(5))  — or propagates failure from either layer
```

---

## Monad Transformers

Validation participates in transformer stacks either as the **outer** layer or as the **inner** layer.

### `ValidationTOptional` — `Validation<E, A?>` (outer = Validation, inner = Optional)

```swift
let v: Validation<[String], Int?> = .success(.some(5))

// <£^> maps inside the Optional without touching the Validation layer
{ $0 * 2 } <£^> v  // .success(Optional(10))

let none: Validation<[String], Int?> = .success(.none)
{ $0 * 2 } <£^> none  // .success(nil)

let failed: Validation<[String], Int?> = .failure(["e"])
{ $0 * 2 } <£^> failed  // .failure(["e"])
```

### `ValidationTArray` — `Validation<E, [A]>` (outer = Validation, inner = Array)

```swift
let v: Validation<[String], [Int]> = .success([1, 2, 3])
{ $0 * 2 } <£^> v  // .success([2, 4, 6])
```

### `ValidationTResult` — `Validation<E, Result<A, Err>>` (outer = Validation, inner = Result)

```swift
let v: Validation<[String], Result<Int, MyError>> = .success(.success(5))
{ $0 * 2 } <£^> v  // .success(.success(10))

// Inner failure passes through the outer success
let innerFail: Validation<[String], Result<Int, MyError>> = .success(.failure(.bad))
{ $0 * 2 } <£^> innerFail  // .success(.failure(.bad))
```

### `OptionalTValidation` — `Validation<E, A>?` (outer = Optional, inner = Validation)

```swift
let v: Validation<[String], Int>? = .success(5)
v?.mapT { $0 * 2 }   // Optional(.success(10))

(nil as Validation<[String], Int>?).map { $0.mapSuccess { $0 * 2 } }  // nil
```

### `ArrayTValidation` — `[Validation<E, A>]` (outer = Array, inner = Validation)

```swift
let vs: [Validation<[String], Int>] = [.success(1), .failure(["e"]), .success(3)]
vs.map { $0.mapSuccess { $0 * 2 } }  // [.success(2), .failure(["e"]), .success(6)]
```

---

## Module

```swift
import DataStructure         // Validation type + named functions
import DataStructureOperators // Operators (<£>, <*>, *>, <*…)
```
