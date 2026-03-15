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

## `<£>` — Map

Apply a function to the right value. Left values pass through unchanged.

```swift
{ $0 * 2 } <£> Either<String, Int>.right(5)       // .right(10)
{ $0 * 2 } <£> Either<String, Int>.left("error")  // .left("error")

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

## `<&>` — Flipped map

Same as `<£>` with the either on the left.

```swift
Either<String, Int>.right(5) <&> { $0 * 2 }      // .right(10)
Either<String, Int>.left("error") <&> { $0 * 2 } // .left("error")
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

## `>>-` — Bind (flatMap)

Chain operations that each may produce a left. Stops at the first left.

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

// Named function
Either.right("42").flatMap(parse)            // .right(42)
Either.bind(validate)(.right(42))            // .right(42)
```

---

## `-<<` — Flipped bind

Same as `>>-` with arguments reversed.

```swift
validate -<< Either.right(42)   // .right(42)
validate -<< Either.right(-1)   // .left("Must be positive: -1")
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

## Module

```swift
import Either        // Either type + named functions
import EitherOperators // Operators (<£>, <*>, >>-, >=>…)
```
