# Result

Swift's `Result<Success, Failure>` extended with functional operators and named functions.

A `Result` is either `.success(value)` or `.failure(error)`. The operators let you transform and chain results without manual `switch` statements.

---

## `<£>` and `<&>` — Map

Apply a function to the success value. `<£>` puts the function on the left; `<&>` puts the result on the left.

```swift
{ $0 * 2 } <£> Result<Int, Error>.success(5)   // .success(10)
{ $0 * 2 } <£> Result<Int, Error>.failure(err) // .failure(err)

Result<Int, Error>.success(5)   <&> { $0 * 2 }  // .success(10)
Result<Int, Error>.failure(err) <&> { $0 * 2 }  // .failure(err)

// Named function
Result<Int, Error>.fmap { $0 * 2 }(.success(5))  // .success(10)
Result.success(5).map { $0 * 2 }                 // .success(10)
```

---

## `£>` and `<£` — Replace

Replace the success value with a constant. Failures pass through unchanged.

```swift
Result<Int, Error>.success(42) £> "done"   // .success("done")
Result<Int, Error>.failure(err) £> "done"  // .failure(err)

"done" <£ Result<Int, Error>.success(42)   // .success("done")

// Named function
Result<Int, Error>.fmap(const("done"))(.success(42))  // .success("done")
```

---

## `<*>` — Apply

Apply a function wrapped in a `Result` to a value wrapped in a `Result`. Both must be `.success`.

```swift
Result<(Int) -> Int, Error>.success({ $0 * 2 }) <*> .success(5)    // .success(10)
Result<(Int) -> Int, Error>.success({ $0 * 2 }) <*> .failure(err)  // .failure(err)
Result<(Int) -> Int, Error>.failure(err) <*> .success(5)            // .failure(err)

// Named function
Result.apply(.success({ $0 * 2 }), .success(5))  // .success(10)
```

---

## `*>` and `<*` — Sequence

Run two results in sequence, keeping only one side's value. If either fails, the failure propagates.

```swift
Result<String, Error>.success("a") *> .success("b")   // .success("b")
Result<String, Error>.failure(err) *> .success("b")   // .failure(err)
Result<String, Error>.success("a") *> .failure(err)   // .failure(err)

Result<String, Error>.success("a") <* .success("b")   // .success("a")
Result<String, Error>.success("a") <* .failure(err)   // .failure(err)

// Named functions
Result.success("a").seqRight(.success("b"))  // .success("b")
Result.success("a").seqLeft(.success("b"))   // .success("a")
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain operations that each may fail. `>>-` puts the container on the left; `-<<` puts the function on the left.

```swift
func parse(_ s: String) -> Result<Int, MyError> {
    Int(s).map(Result.success) ?? .failure(.invalidInput)
}
func validate(_ n: Int) -> Result<Int, MyError> {
    n > 0 ? .success(n) : .failure(.outOfRange)
}

Result.success("42") >>- { parse($0) } >>- validate  // .success(42)
Result.success("-1") >>- { parse($0) } >>- validate  // .failure(.outOfRange)
Result.success("??") >>- { parse($0) }               // .failure(.invalidInput)

validate -<< Result.success(42)   // .success(42)
validate -<< Result.success(-1)   // .failure(.outOfRange)

// Named function
Result.bind(validate)(Result.success(42))  // .success(42)
Result.success(42).flatMap(validate)       // .success(42)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Result`, producing a single function.

```swift
func parse(_ s: String)  -> Result<Int, MyError> { ... }
func validate(_ n: Int)  -> Result<Int, MyError> { ... }
func doubled(_ n: Int)   -> Result<Int, MyError> { .success(n * 2) }

let pipeline = parse >=> validate >=> doubled
pipeline("21")   // .success(42)
pipeline("-1")   // .failure(.outOfRange)  (fails at validate)
pipeline("??")   // .failure(.invalidInput) (fails at parse)

// Named function
Result.kleisli(parse, validate)("21")  // .success(42)
```

---

## `<|>` — Alternative

Return the first `.success`, or the last `.failure` if both fail.

```swift
Result<Int, Error>.failure(err) <|> .success(3)   // .success(3)
Result<Int, Error>.success(1)   <|> .success(3)   // .success(1)
Result<Int, Error>.failure(e1)  <|> .failure(e2)  // .failure(e2)
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

## Module

```swift
import FP       // Named functions (fmap, apply, seqRight, bind, kleisli…)
import Operators // Operators (<£>, <*>, >>-, >=>…)
```
