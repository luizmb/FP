# DeferredTask

`DeferredTask<A>` is a wrapper for a lazy async computation `() async -> A`.

It solves the **deferred execution** problem: a `Task` in Swift starts running the moment you create it. `DeferredTask` lets you *describe* an async computation as a value — compose it, transform it, chain it — without running anything until you explicitly call `.run()`. This makes async code as composable and testable as pure functions.

```swift
import CoreFP

let fetchUser = DeferredTask<User> {
    await api.getUser(id: 42)
}

// Nothing has happened yet. The network call hasn't started.
let user = await fetchUser.run()  // Only now does it execute
```

---

## `<£>` and `<&>` — Map

Transform the result of a task without running it.

```swift
let fetchName = { $0.name } <£> fetchUser   // DeferredTask<String> — still deferred
let name = await fetchName.run()            // runs and maps in one shot

fetchUser <&> { $0.name }  // same, container on left

// Named function
fetchUser.fmap { $0.name }
DeferredTask.fmap { $0.name }(fetchUser)
```

---

## `£>` and `<£` — Replace

Replace the result with a constant. The task still runs (for its side effects), but its value is discarded.

```swift
let pingOnly = fetchUser £> ()   // DeferredTask<Void> — runs but discards result
await pingOnly.run()

() <£ fetchUser  // same

// Named function
fetchUser.replace(())
```

---

## `<*>` — Apply (parallel execution)

Apply a task-wrapped function to a task-wrapped value. Both tasks start concurrently.

```swift
let applyTransform = DeferredTask<(User) -> String> { await loadFormatter() }
let fetchedUser    = fetchUser

let result = await (applyTransform <*> fetchedUser).run()
// Both loadFormatter() and getUser() run concurrently

// Named function
applyDeferredTask(applyTransform, fetchedUser)
```

---

## `*>` and `<*` — Sequence

Run two tasks (concurrently if possible), keeping only one result.

```swift
let log    = DeferredTask<Void>   { await analytics.track("fetch") }
let fetch  = DeferredTask<String> { await api.getName() }

await (log *> fetch).run()   // both run, only fetch result returned
await (fetch <* log).run()   // both run, only fetch result returned

// Named functions
fetch.seqRight(log)
fetch.seqLeft(log)
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain two tasks where the second depends on the result of the first. They run serially.

```swift
let fetchPermissions = fetchUser >>- { user in
    DeferredTask { await api.getPermissions(for: user) }
}
// user must finish before permissions fetch can start

let permissions = await fetchPermissions.run()

// Contrast with <*>: use >>- when step 2 depends on step 1's result
//                    use <*> / zip when steps are independent

// Named functions
fetchUser.flatMap { user in DeferredTask { await api.getPermissions(for: user) } }
DeferredTask.flatMap { user in DeferredTask { await api.getPermissions(for: user) } }(fetchUser)
```

---

## `>=>` — Kleisli composition

Compose two async functions into one pipeline.

```swift
let fetchUser:   (Int)  -> DeferredTask<User>    = { id in DeferredTask { await api.getUser(id: id) } }
let fetchOrders: (User) -> DeferredTask<[Order]> = { user in DeferredTask { await api.getOrders(for: user) } }
let summarise:   ([Order]) -> DeferredTask<String> = { orders in DeferredTask { "\(orders.count) orders" } }

let pipeline = fetchUser >=> fetchOrders >=> summarise
let summary = await pipeline(42).run()  // "N orders"

// Named function
DeferredTask.kleisli(fetchUser, fetchOrders)(42)
```

---

## Zip — parallel combination

`zip` runs multiple independent tasks concurrently and combines their results.

```swift
// Two tasks run at the same time
let (user, config) = await DeferredTask.zip(fetchUser, fetchConfig).run()

// Three independent tasks
let (user, config, flags) = await DeferredTask.zip(fetchUser, fetchConfig, fetchFlags).run()

// liftA2 — combine results with a function
let greeting = await DeferredTask.liftA2 { user, config in
    "\(config.greeting), \(user.name)!"
}(fetchUser, fetchConfig).run()
```

---

## Running a DeferredTask

```swift
// run() — await the result directly
let result = await myTask.run()

// eraseToTask() — convert to a Swift Task if you need to store it or cancel it
let task: Task<A, Never> = myTask.eraseToTask()
let result = await task.value
task.cancel()
```

---

## Monad Transformers

### `DeferredTaskTOptional` — `DeferredTask<A?>` (outer = DeferredTask, inner = Optional)

A deferred computation that may or may not produce a value.

```swift
let maybeUser: DeferredTask<User?> = DeferredTask { await api.findUser(name: "Alice") }

{ $0.name } <£^> maybeUser   // DeferredTask<String?> — maps inside Optional
let name = await ({ $0.name } <£^> maybeUser).run()  // String?
```

### `DeferredTaskTResult` — `DeferredTask<Result<A, E>>` (outer = DeferredTask, inner = Result)

A deferred computation that may fail with a typed error.

```swift
let fetchResult: DeferredTask<Result<User, APIError>> = DeferredTask {
    do { return .success(try await api.getUser(id: 42)) }
    catch { return .failure(error as! APIError) }
}

{ $0.name } <£^> fetchResult   // DeferredTask<Result<String, APIError>>
```

### `DeferredTaskTArray` — `DeferredTask<[A]>` (outer = DeferredTask, inner = Array)

A deferred computation that produces a collection.

```swift
let fetchAll: DeferredTask<[User]> = DeferredTask { await api.getAllUsers() }

{ $0.name } <£^> fetchAll   // DeferredTask<[String]>
```

---

## Module

```swift
import CoreFP          // DeferredTask type + named functions
import CoreFPOperators // Operators (<£>, <*>, >>-, >=>…)
```
