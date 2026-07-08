# AsyncSequence

`AsyncStream` extended with functional operators and named functions.

An `AsyncStream<Element>` emits values asynchronously over time. The operators let you transform and chain streams using the same patterns as `Optional`, `Result`, and `Array`.

> Requires macOS 10.15+, iOS 13.0+. Concurrency context (`async`/`await`) required at the call site.

---

## `<£>` and `<&>` — Map

Apply a function to every emitted element. `<£>` puts the function on the left; `<&>` puts the stream on the left.

```swift
let numbers = AsyncStream<Int> { c in c.yield(1); c.yield(2); c.yield(3); c.finish() }

{ (n: Int) async -> Int in n * 2 } <£> numbers   // emits 2, 4, 6
numbers <&> { (n: Int) async -> Int in n * 2 }   // emits 2, 4, 6

// Named function — uses AsyncSequence.map under the hood
numbers.map { $0 * 2 }
```

---

## `£>` and `<£` — Replace

Replace every emitted element with a constant.

```swift
numbers £> "tick"    // emits "tick", "tick", "tick"
"tick" <£ numbers    // same
```

---

## `<*>` — Apply

Zip a stream of functions with a stream of values, applying each pair.

```swift
let fns = AsyncStream<@Sendable (Int) -> Int> { c in
    c.yield { $0 + 1 }
    c.yield { $0 * 10 }
    c.finish()
}

fns <*> numbers   // emits 2 (1+1), 20 (2*10), stops when either stream ends

// Named function
AsyncStream.apply(fns, numbers)
```

---

## `*>` and `<*` — Sequence

Zip two streams, keeping only one side's values.

```swift
let letters = AsyncStream<String> { c in c.yield("a"); c.yield("b"); c.finish() }

numbers *> letters   // emits "a", "b"  (numbers consumed but discarded)
numbers <* letters   // emits 1, 2      (letters consumed but discarded)

// Named functions
AsyncStream.seqRight(numbers, letters)
AsyncStream<String>.seqRight(numbers, letters)
```

---

## `>>-` and `-<<` — Bind (flatMap)

For each emitted element, produce a new async sequence and flatten the results. `>>-` puts the stream on the left; `-<<` puts the function on the left.

```swift
numbers >>- { n in AsyncStream<Int> { c in c.yield(n); c.yield(n * 10); c.finish() } }
// emits 1, 10, 2, 20, 3, 30

{ n in AsyncStream<Int> { c in c.yield(n * 2); c.finish() } } -<< numbers
// emits 2, 4, 6
```

---

## `>=>` — Kleisli composition

Compose two functions that each return an `AsyncStream`.

```swift
let expand:  (Int) -> AsyncStream<Int> = { n in AsyncStream { c in c.yield(n); c.yield(n + 1); c.finish() } }
let doubled: (Int) -> AsyncStream<Int> = { n in AsyncStream { c in c.yield(n * 2); c.finish() } }

let pipeline = expand >=> doubled
// pipeline(3) emits 6, 8  — expand gives 3 and 4, doubled gives 6 and 8
```

---

## ReaderT — AsyncStream with environment

Combine `Reader` and `AsyncStream` to describe environment-dependent async sequences.

```swift
import DataStructure
import DataStructureOperators

protocol EventSource {
    func events() -> AsyncStream<Event>
}

let listen = Reader<any EventSource, AsyncStream<Event>> { source in
    source.events()
}

// mapT maps inside the AsyncStream without touching the Reader layer
let eventNames = listen.mapT { $0.name }
// Reader<any EventSource, AsyncStream<String>>

// Provide the dependency at the edge
let stream = eventNames(LiveEventSource())

// Swap for tests
let testStream = eventNames(StubEventSource(events: [testEvent]))
```

---

## Monad Transformers

AsyncStream can be the outer layer of a transformer stack. The transformer name is `AsyncSequenceT{Inner}`.

### `AsyncSequenceTOptional` — `AsyncStream<A?>`

AsyncStream emitting optional values. `nil` elements stay `nil`.

```swift
import FP

let stream = AsyncStream<Int?> { c in
    c.yield(1); c.yield(nil); c.yield(3); c.finish()
}

// mapT — transform inner Optional without affecting the stream layer
let doubled = mapTAsyncStreamOptional({ $0 * 2 }, stream)
// emits Optional(2), nil, Optional(6)

// liftA2 — zip two streams and combine inner Optional values
let sa = AsyncStream<Int?>.just(Optional(3))
let sb = AsyncStream<Int?>.just(Optional(4))
liftA2AsyncStreamOptional(+)(sa, sb)   // emits Optional(7)

// flatMapT — each Optional element produces a new AsyncStream<B?>
let bound = flatMapTAsyncStreamOptional(stream) { n in
    AsyncStream<Int?>.just(Optional(n * 2))
}
// emits Optional(2), nil, Optional(6)

// Operators
{ $0 * 2 } <£> stream   // emits Optional(2), nil, Optional(6)
stream >>- { n in AsyncStream<Int?>.just(n.map { $0 + 1 }) }
```

### `AsyncSequenceTArray` — `AsyncStream<[A]>`

AsyncStream emitting arrays. Inner elements are transformed as a group.

```swift
import FP

let stream = AsyncStream<[Int]> { c in
    c.yield([1, 2]); c.yield([3, 4]); c.finish()
}

mapTAsyncStreamArray({ $0 * 2 }, stream)
// emits [2, 4], [6, 8]

// liftA2 — zip and combine with Array.liftA2
let sa = AsyncStream<[Int]>.just([1, 2])
let sb = AsyncStream<[Int]>.just([10, 20])
liftA2AsyncStreamArray(+)(sa, sb)   // emits [11, 21, 12, 22]

{ $0 * 2 } <£> stream   // emits [2, 4], [6, 8]
```

### `AsyncSequenceTResult` — `AsyncStream<Result<A,E>>`

AsyncStream emitting Results. `.failure` elements propagate the inner error.

```swift
import FP

let stream = AsyncStream<Result<Int, MyError>> { c in
    c.yield(.success(5)); c.yield(.failure(.bad)); c.finish()
}

mapTAsyncStreamResult({ $0 * 2 }, stream)  // emits .success(10), .failure(.bad)
flatMapTAsyncStreamResult(stream) { n in
    AsyncStream<Result<String, MyError>>.just(.success("\(n)"))
}
// emits .success("5"), .failure(.bad)
```

### `AsyncSequenceTEither` — `AsyncStream<Either<L,A>>`

AsyncStream emitting Either values.

```swift
import DataStructure

let stream = AsyncStream<Either<String, Int>> { c in
    c.yield(.right(1)); c.yield(.left("err")); c.yield(.right(3)); c.finish()
}

mapTAsyncStreamEither({ $0 * 2 }, stream)  // emits .right(2), .left("err"), .right(6)
flatMapTAsyncStreamEither(stream) { n in
    AsyncStream<Either<String, Int>>.just(.right(n * 2))
}
// emits .right(2), .left("err"), .right(6)

// Operators (EitherOperators)
{ $0 * 2 } <£> stream
```

---

## Module

```swift
import FP        // Named functions (apply, seqRight, bind…) + AsyncSequenceT stacks
import CoreFPOperators  // Operators (<£>, <*>, >>-, >=>…) for AsyncStream and AsyncSequenceT stacks

// For AsyncSequenceTEither:
import DataStructure
import DataStructureOperators

// For ReaderT + AsyncStream:
import DataStructure
import DataStructureOperators
```

---

## For Haskell developers

There's no tight Haskell analog here — `AsyncStream` is Swift's native effectful, push-based, single-consumer async sequence, tied to structured concurrency (`async`/`await`) rather than to a general streaming abstraction. The closest prior art in Haskell is the family of effectful streaming libraries — `streaming`, `pipes`, or `conduit` — which model a lazy sequence of values interleaved with effects (there, typically `IO`) the same way `AsyncStream<Element>` interleaves values with suspension points.

| This library | Rough Haskell parallel |
|---|---|
| `AsyncStream<Element>` | `Stream (Of Element) IO ()` (`streaming`) / `Producer Element IO ()` (`pipes`) / `ConduitT () Element IO ()` (`conduit`) |
| `<£>` / `.map` | `Streaming.Prelude.map` / `pipes`'s `for`+`yield` mapping |
| `>>-` / `.flatMap` | streaming bind, roughly `Streaming`'s monadic `do`-block chaining over `Stream`, or `conduit`'s `.|` composition |
| `>=>` (Kleisli) | Kleisli composition of `a -> Stream (Of b) IO ()`-shaped functions |

Keep the mapping loose — none of these libraries share `AsyncStream`'s exact cancellation/backpressure model, and Swift's version is scoped to structured concurrency rather than a standalone streaming DSL.

**References:**
- [`streaming`](https://hackage.haskell.org/package/streaming) — effectful, `IO`-interleaved streams closest in spirit to `AsyncStream`
