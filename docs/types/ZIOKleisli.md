# ZIOKleisli

`ZIOKleisli<Input, Env, Success, Failure>` is a first-class Kleisli arrow in the ZIO monad:

```
ZIOKleisli<Input, Env, Success, Failure>
≅ (Input) -> ZIO<Env, Success, Failure>
≅ (Input) -> Env -> DeferredTask<Result<Success, Failure>>
```

It wraps a function from some input type to a `ZIO`, promoting it into a named value with its own Functor, Monad, and Kleisli composition operations. Two composition levels exist in this library:

| Level | Operator / function | Result type |
|-------|--------------------|-|
| Plain function level | `>=>` on `(X) -> ZIO` functions | `(X) -> ZIO` plain function |
| `ZIOKleisli` level | `andThen` / `kleisli` / `>=>` | `ZIOKleisli` — first-class, storable, composable |

Use the plain-function level when you only need to compose two steps inline. Use `ZIOKleisli` when you need to store the composed arrow, pass it around, or compose further.

```swift
import DataStructure

enum AppError: Error { case notFound }
struct DB { func find(id: Int) async -> String? { ... } }

// A Kleisli arrow: given an Int input, produce a ZIO
let lookupUser = ZIOKleisli<Int, DB, String, AppError> { id in
    ZIO { db in DeferredTask {
        guard let user = await db.find(id: id) else { return .failure(.notFound) }
        return .success(user)
    }}
}

// Call with an input — produces a ZIO
let zio = lookupUser(42)         // ZIO<DB, String, AppError>
let result = await zio.provide(DB()).run()  // Result<String, AppError>
```

---

## Construction

```swift
// From a closure
let parse = ZIOKleisli<String, Void, Int, Never> { s in .pure(Int(s) ?? 0) }

// Lift a ZIO — ignores the input
let constant = ZIOKleisli<Bool, Void, String, Never>.lift(ZIO.pure("hello"))

// Lift a pure value — input and environment both ignored
let pure = ZIOKleisli<String, Int, Int, Never>.pure(42)
```

---

## `map` — transform the success value

```swift
let doubled = lookupUser.map { name in name.uppercased() }
// ZIOKleisli<Int, DB, String, AppError>
```

---

## `mapError` — transform the failure

```swift
let mapped = lookupUser.mapError { _ in AppError.notFound }
```

---

## `replace` — substitute a constant on success

```swift
let found = lookupUser.replace(true)   // ZIOKleisli<Int, DB, Bool, AppError>
```

---

## `flatMap` — sequential composition (same `Input`)

The same input value is threaded into both sides.

```swift
let lookupAndGreet = lookupUser.flatMap { name in
    ZIOKleisli<Int, DB, String, AppError> { _ in .pure("Hello, \(name)!") }
}
```

---

## `andThen` / `compose` — Kleisli category composition (changes `Input`)

Feed the output of one arrow as the input of the next.

```swift
let toString  = ZIOKleisli<Int, DB, String, AppError> { id in .pure("\(id)") }
let countChars = ZIOKleisli<String, DB, Int, AppError> { s in .pure(s.count) }

let pipeline = toString.andThen(countChars)   // ZIOKleisli<Int, DB, Int, AppError>
let result   = await pipeline(1234).provide(DB()).run()   // .success(4)

// compose is andThen in reverse argument order
let same = countChars.compose(toString)   // equivalent

// Static kleisli helper
let same2 = ZIOKleisli<Int, DB, String, AppError>.kleisli(toString, countChars)
```

---

## `>=>` — Kleisli composition operator

```swift
// At the function level — result is a plain (X) -> ZIO function:
let f: @Sendable (Int)    -> ZIO<DB, String, AppError>
let g: @Sendable (String) -> ZIO<DB, Int, AppError>
let h = f >=> g   // @Sendable (Int) -> ZIO<DB, Int, AppError>

// At the ZIOKleisli level — result is a ZIOKleisli value:
let pipeline: ZIOKleisli<Int, DB, Int, AppError> = toString >=> countChars
```

---

## `join` — flatten a nested `ZIOKleisli`

```swift
let inner = ZIOKleisli<Int, Int, Int, Never>.pure(7)
let outer = ZIOKleisli<Int, Int, ZIOKleisli<Int, Int, Int, Never>, Never>.pure(inner)
let flat  = ZIOKleisli<Int, Int, ZIOKleisli<Int, Int, Int, Never>, Never>.join(outer)
```

---

## `flatMapError` — recover from failures

```swift
let recovered = lookupUser.flatMapError { _ in
    ZIOKleisli<Int, DB, String, AppError>.pure("default")
}
```

---

## `void` — discard success value

```swift
let effect = lookupUser.void()   // ZIOKleisli<Int, DB, Void, AppError>
```

---

## Module

```swift
import DataStructure          // ZIOKleisli type + named functions
import DataStructureOperators // Operators (<£>, >>-, >=>…)
```
