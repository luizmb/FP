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

## `contramap` — narrow the input (contravariant functor on `Input`)

Transform the *input* before it reaches the arrow, letting it accept a wider (or different) input type.

```swift
// lookupUser :: ZIOKleisli<Int, DB, String, AppError>
// Adapt to accept String IDs instead
let lookupByStringId: ZIOKleisli<String, DB, String, AppError> =
    lookupUser.contramap { Int($0) ?? 0 }

// Static variant
let adapt = ZIOKleisli<Int, DB, String, AppError>.contramap { Int($0) ?? 0 }

// Free function
let k2 = contramapZIOKleisli({ Int($0) ?? 0 }, lookupUser)

// Operator — `>>>` feeds the input-transform into the ZIOKleisli
let k3 = ({ Int($0) ?? 0 } as @Sendable (String) -> Int) >>> lookupUser
```

---

## `contramapEnvironment` — narrow the environment (contravariant functor on `Env`)

Transform the *environment* before it is supplied to the inner ZIO.

```swift
struct AppEnv { var db: DB }

let appLookup: ZIOKleisli<Int, AppEnv, String, AppError> =
    lookupUser.contramapEnvironment(\.db)

// Static variant
let adapt = ZIOKleisli<Int, DB, String, AppError>.contramapEnvironment(\.db)

// Free function
let k2 = contramapEnvironmentZIOKleisli(\.db, lookupUser)

// Operator — `>>>` feeds the env-transform into the ZIOKleisli
let k3 = (\.db as @Sendable (AppEnv) -> DB) >>> lookupUser
```

---

## `dimap` — transform input, environment, and output together

Combines `contramap` (on `Input`), `contramapEnvironment` (on `Env`), and `map` (on `Success`) in one step.

```swift
struct AppEnv { var db: DB }

let fullAdapter: ZIOKleisli<String, AppEnv, String, AppError> =
    lookupUser.dimap(
        { Int($0) ?? 0 },  // (String) -> Int   — narrow input
        \.db,               // (AppEnv) -> DB    — narrow env
        { $0.uppercased() } // (String) -> String — transform output
    )

// Static variant
ZIOKleisli<Int, DB, String, AppError>.dimap(
    { Int($0) ?? 0 }, \.db, { $0.uppercased() }
)(lookupUser)

// Free function
dimapZIOKleisli({ Int($0) ?? 0 }, \.db, { $0.uppercased() }, lookupUser)
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
