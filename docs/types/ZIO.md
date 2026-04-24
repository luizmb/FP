# ZIO

`ZIO<Env, Success, Failure>` is a three-layer monad stack:

```
ReaderT Env (ExceptT Failure DeferredTask) Success
≅ Env -> DeferredTask<Result<Success, Failure>>
```

It combines dependency injection (`Reader`), typed error handling (`Result`), and deferred async execution (`DeferredTask`) into a single composable type. The environment is supplied once via `provide`; nothing executes until the resulting `DeferredTask` is `.run()`.

Generic parameter order mirrors `Result<Success, Failure>` and Swift convention:

| Parameter | Role |
|-----------|------|
| `Env` | Required environment / dependencies |
| `Success` | Value produced on the happy path |
| `Failure` | Typed error |

```swift
import DataStructure

enum AppError: Error { case notFound }
struct DB { func find(id: Int) async -> String? { ... } }

let fetchUser: ZIO<DB, String, AppError> = ZIO { db in
    DeferredTask {
        guard let user = await db.find(id: 42) else { return .failure(.notFound) }
        return .success(user)
    }
}

// Provide the environment and run
let result = await fetchUser.provide(DB()).run()  // Result<String, AppError>
```

---

## Construction

```swift
// From a closure
let greet: ZIO<String, String, Never> = ZIO { name in
    .pure(.success("Hello, \(name)!"))
}

// Lift a pure value — environment is ignored
let pure = ZIO<String, Int, Never>.pure(42)

// Ask for the whole environment
let env = ZIO<String, String, Never>.ask         // ZIO that succeeds with the Env itself

// Transform the environment before use
let length = ZIO<String, Int, Never>.asks(\.count)  // success = env.count

// Supply a modified environment to self (does not escape the Env type)
let local = greet.local { name in "Dr. \(name)" }  // transforms env before injection
```

---

## `map` — transform the success value

```swift
let doubled = ZIO<Int, Int, Never>.pure(21).map { $0 * 2 }
let result  = await doubled.provide(0).run()  // .success(42)

// Static fmap variant for point-free composition
let tripler: (ZIO<Int, Int, Never>) -> ZIO<Int, Int, Never> = ZIO.fmap { $0 * 3 }
```

---

## `mapError` — transform the failure value

```swift
enum AppError: Error { case raw(String) }
enum UIError: Error  { case message(String) }

let mapped = someZIO.mapError { raw in UIError.message(raw.localizedDescription) }
```

---

## `replace` — discard success value, substitute a constant

```swift
let unit = ZIO<Int, Int, Never>.pure(42).replace(())  // ZIO<Int, Void, Never>
```

---

## `<*>` — Apply (parallel execution)

Apply a ZIO-wrapped function to a ZIO-wrapped value. Both use the same environment.

```swift
let fn:  ZIO<Int, @Sendable (Int) -> Int, Never> = .pure({ $0 * 5 })
let val: ZIO<Int, Int, Never>                    = .pure(3)

let result = await applyZIO(fn, val).provide(0).run()  // .success(15)

// liftA2 — combine two ZIOs with a binary function
let sum = liftA2ZIO { a, b in a + b }(ZIO.pure(3), ZIO.pure(4))
```

---

## `flatMap` — sequential composition

Chain ZIOs where the second depends on the result of the first.

```swift
let pipeline = ZIO<DB, String, AppError>.pure("Alice")
    .flatMap { name in ZIO { db in DeferredTask { .success(await db.greet(name)) } } }

// Static bind variant for point-free composition
let bound = ZIO<DB, String, AppError>.bind { name in
    ZIO { db in DeferredTask { .success(await db.greet(name)) } }
}

// flatMapError — recover from failures
let recovered = failingZIO.flatMapError { _ in ZIO.pure(defaultValue) }
```

---

## `join` — flatten nested ZIOs

```swift
let nested: ZIO<Int, ZIO<Int, String, Never>, Never> = .pure(.pure("hello"))
let flat:   ZIO<Int, String, Never> = ZIO.join(nested)
```

---

## `>=>` / `<=<` — Kleisli composition

Compose two functions that each return a `ZIO`.

```swift
let parse:    @Sendable (String) -> ZIO<DB, Int, AppError> = { s in .pure(Int(s) ?? 0) }
let lookup:   @Sendable (Int) -> ZIO<DB, String, AppError> = { id in ... }

let pipeline = parse >=> lookup   // (String) -> ZIO<DB, String, AppError>

// Named functions
let f = ZIO<DB, Int, AppError>.kleisli(parse, lookup)
```

---

## `seqRight` / `seqLeft` — sequence effects, discard one result

```swift
let log = ZIO<DB, Void, Never>.pure(())  // logging side effect
let fetch: ZIO<DB, String, AppError> = ...

let withLog = log.seqRight(fetch)   // log runs first, fetch result returned
```

---

## `void` — discard success value

```swift
let sideEffect = fetchUser.void()   // ZIO<DB, Void, AppError>
```

---

## `provide` / `callAsFunction`

```swift
// Both are equivalent — supply the environment and get back a DeferredTask
let task: DeferredTask<Result<String, AppError>> = fetchUser.provide(DB())
let same: DeferredTask<Result<String, AppError>> = fetchUser(DB())

let result = await task.run()
```

---

## Module

```swift
import DataStructure          // ZIO type + named functions
import DataStructureOperators // Operators (<£>, <*>, >>-, >=>…)
```
