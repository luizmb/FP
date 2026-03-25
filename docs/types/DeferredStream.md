# DeferredStream

`DeferredStream<A>` is a lazy `AsyncSequence` whose production doesn't start until you begin iterating.

Swift's `AsyncStream` starts its producer closure at construction time. `DeferredStream` defers that entirely — nothing runs until `makeAsyncIterator()` is called (i.e., until you `for await` over it or pass it to something that iterates). This makes streams as composable and reusable as values: you can describe, transform, and chain them before deciding to run them.

```swift
import CoreFP

let stream = DeferredStream<Int> {
    AsyncStream { continuation in
        Task {
            for i in 1...5 {
                continuation.yield(i)
            }
            continuation.finish()
        }
    }
}

// Nothing has started yet. Iteration begins only when you consume it:
for await value in stream {
    print(value)  // 1, 2, 3, 4, 5
}
```

---

## `<£>` and `<&>` — Map

Transform each element of a stream without starting it.

```swift
let doubled = { $0 * 2 } <£> stream   // DeferredStream<Int> — still deferred

for await value in doubled { print(value) }  // 2, 4, 6, 8, 10

stream <&> { $0 * 2 }  // same, stream on left

// Named function
stream.fmap { $0 * 2 }
DeferredStream.fmap { $0 * 2 }(stream)
```

---

## `£>` and `<£` — Replace

Replace every emitted element with a constant.

```swift
let pings = stream £> "ping"   // DeferredStream<String> — emits "ping" for each element

for await value in pings { print(value) }  // "ping", "ping", "ping", "ping", "ping"

"tick" <£ stream  // same

// Named function
stream.replace("ping")
```

---

## `<*>` — Apply

Apply a stream of functions to a stream of values, producing all combinations.

```swift
let functions = DeferredStream<(Int) -> Int>.wrap(AsyncStream.just({ $0 + 1 }, { $0 * 10 }))
let values    = DeferredStream<Int>.wrap(AsyncStream.just(1, 2))

// Each function applied to each value:
for await value in (functions <*> values) { print(value) }
// 2, 3, 10, 20

// Named function
applyDeferredStream(functions, values)
```

---

## `*>` and `<*` — Sequence

Concatenate two streams, keeping only one side's elements.

```swift
let first  = DeferredStream<String>.wrap(AsyncStream.just("a", "b"))
let second = DeferredStream<String>.wrap(AsyncStream.just("x", "y"))

for await v in (first *> second) { print(v) }  // "x", "y"  (first runs to completion, then second)
for await v in (first <* second) { print(v) }  // "a", "b"  (second is consumed but discarded)

// Named functions
first.seqRight(second)
first.seqLeft(second)
```

---

## `>>-` and `-<<` — Bind (flatMap)

For each element in a stream, produce a new stream. All produced streams are concatenated.

```swift
let ids = DeferredStream<Int>.wrap(AsyncStream.just(1, 2, 3))

let users = ids >>- { id in
    DeferredStream<User> { AsyncStream { cont in
        Task { cont.yield(await api.getUser(id: id)); cont.finish() }
    }}
}

for await user in users { print(user.name) }  // users fetched one at a time, in order

// Named functions
ids.flatMap { id in fetchUserStream(id) }
DeferredStream.flatMap { id in fetchUserStream(id) }(ids)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `DeferredStream`.

```swift
let expand: (Int) -> DeferredStream<Int> = { n in
    DeferredStream.wrap(AsyncStream.just(n, n * 10))
}
let format: (Int) -> DeferredStream<String> = { n in
    DeferredStream.wrap(AsyncStream.just("val:\(n)"))
}

let pipeline = expand >=> format
for await s in pipeline(3) { print(s) }  // "val:3", "val:30"

// Named function
DeferredStream.kleisli(expand, format)(3)
```

---

## `<|>` — Alternative

Concatenate two streams end-to-end (the second starts when the first finishes).

```swift
let a = DeferredStream<Int>.wrap(AsyncStream.just(1, 2))
let b = DeferredStream<Int>.wrap(AsyncStream.just(3, 4))

for await v in (a <|> b) { print(v) }  // 1, 2, 3, 4
```

---

## Zip — parallel combination

`zip` pairs elements from two streams as they arrive (one pair per emission from each).

```swift
let names   = DeferredStream<String>.wrap(AsyncStream.just("Alice", "Bob"))
let scores  = DeferredStream<Int>.wrap(AsyncStream.just(95, 87))

let paired = DeferredStream.zip(names, scores)
for await (name, score) in paired { print("\(name): \(score)") }
// "Alice: 95", "Bob: 87"

// liftA2 — combine with a function
let summary = DeferredStream.liftA2 { name, score in "\(name) scored \(score)" }(names, scores)
```

---

## Wrapping an existing AsyncStream

```swift
// From an existing AsyncStream
let existing: AsyncStream<Int> = ...
let deferred = DeferredStream.wrap(existing)

// From an AsyncSequence (any)
let deferred2 = DeferredStream<Int> {
    AsyncStream { continuation in
        Task {
            for await value in someAsyncSequence {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }
}
```

---

## Monad Transformers

### `DeferredStreamTOptional` — `DeferredStream<A?>` (outer = DeferredStream, inner = Optional)

A stream where each element may or may not be present.

```swift
let maybeValues: DeferredStream<Int?> = DeferredStream {
    AsyncStream { cont in
        Task { cont.yield(.some(1)); cont.yield(nil); cont.yield(.some(3)); cont.finish() }
    }
}

{ $0 * 2 } <£^> maybeValues   // DeferredStream<Int?> — maps inside each Optional

for await v in ({ $0 * 2 } <£^> maybeValues) { print(v) }
// Optional(2), nil, Optional(6)
```

### `DeferredStreamTResult` — `DeferredStream<Result<A, E>>` (outer = DeferredStream, inner = Result)

A stream of fallible values.

```swift
let results: DeferredStream<Result<Int, MyError>> = DeferredStream {
    AsyncStream { cont in
        Task {
            cont.yield(.success(1))
            cont.yield(.failure(.bad))
            cont.yield(.success(3))
            cont.finish()
        }
    }
}

{ $0 * 2 } <£^> results   // DeferredStream<Result<Int, MyError>>
// .success(2), .failure(.bad), .success(6)
```

### `DeferredStreamTArray` — `DeferredStream<[A]>` (outer = DeferredStream, inner = Array)

A stream where each emission is a batch.

```swift
let batches: DeferredStream<[Int]> = DeferredStream {
    AsyncStream { cont in
        Task { cont.yield([1, 2]); cont.yield([3, 4, 5]); cont.finish() }
    }
}

{ $0 * 2 } <£^> batches   // DeferredStream<[Int]>
// [2, 4], [6, 8, 10]
```

---

## Module

```swift
import CoreFP          // DeferredStream type + named functions
import CoreFPOperators // Operators (<£>, <*>, >>-, >>>…)
```
