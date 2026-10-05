# ``_Concurrency/AsyncSequence``

`AsyncStream` extended with functional operators and named functions.

An `AsyncStream<Element>` emits values asynchronously over time. The operators let you transform and chain streams using the same patterns as `Optional`, `Result`, and `Array`.

> Requires macOS 10.15+, iOS 13.0+. Concurrency context (`async`/`await`) required at the call site.

---

## `<£>` and `<&>` — Map

Apply a function to every emitted element. `<£>` puts the function on the left; `<&>` puts the stream on the left.

```swift
let numbers = AsyncStream<Int> { c in c.yield(1); c.yield(2); c.yield(3); c.finish() }

_ = { (n: Int) async -> Int in n * 2 } <£> numbers   // emits 2, 4, 6
_ = numbers <&> { (n: Int) async -> Int in n * 2 }   // emits 2, 4, 6

// Named function, uses AsyncSequence.map under the hood
_ = numbers.map { $0 * 2 }
```

---

## `£>` and `<£` — Replace

Replace every emitted element with a constant.

```swift
_ = numbers £> "tick"    // emits "tick", "tick", "tick"
_ = "tick" <£ numbers    // same
```

---

## `<*>` — Apply

The applicative is derived from bind (`<*>` == `ap`), with Haskell stream semantics: for each function, in order, map it over the whole argument stream. It is cartesian, like the list applicative, not zip.

```swift
let fns = AsyncStream<@Sendable (Int) -> Int> { c in
    c.yield { $0 + 1 }
    c.yield { $0 * 10 }
    c.finish()
}

_ = fns <*> numbers   // emits 2, 3, 4 (each +1), then 10, 20, 30 (each *10)

// Named functions
_ = AsyncStream<Int>.apply(fns, numbers)
_ = AsyncStream<Int>.liftA2(+)(numbers, numbers)   // 2, 3, 4, 3, 4, 5, 4, 5, 6
```

An `AsyncStream` can be iterated only once, but `ap` walks the argument once per function. The argument is therefore drained once into a buffer (when the first function arrives) and replayed for every function: order is kept and nothing is lost, but the argument must be finite. The same mechanism is public as `AsyncStream.replayable(_:)`.

---

## `*>` and `<*` — Sequence

Derived from bind too: `a *> b = a >>= \_ -> b`, `a <* b = a >>= \x -> fmap (const x) b`. The left stream runs first; the right stream is drained once and replayed for each left element.

```swift
let letters = AsyncStream<String> { c in c.yield("a"); c.yield("b"); c.finish() }

_ = numbers *> letters   // emits "a", "b", "a", "b", "a", "b"
_ = numbers <* letters   // emits 1, 1, 2, 2, 3, 3

// Named functions
_ = AsyncStream<String>.seqRight(numbers, letters)
_ = AsyncStream<Int>.seqLeft(numbers, letters)
```

---

## `zip` — Pairing

To pair elements positionally (the old `<*>` behaviour), use `zip`. It is a named function only, not the applicative.

```swift
_ = AsyncStream<(Int, String)>.zip(numbers, letters)   // emits (1, "a"), (2, "b"), stops when either ends
_ = AsyncStream<String>.zip(numbers, letters).map { n, s in "\(s)\(n)" }   // zipWith
```

---

## `>>-` and `-<<` — Bind (flatMap)

For each emitted element, produce a new async sequence and flatten the results by ordered concat: each inner sequence runs to completion, in upstream order, before the next upstream element is pulled; nothing is dropped. `>>-` puts the stream on the left; `-<<` puts the function on the left.

```swift
_ = numbers >>- { n in AsyncStream<Int> { c in c.yield(n); c.yield(n * 10); c.finish() } }
// emits 1, 10, 2, 20, 3, 30

_ = { (n: Int) in AsyncStream<Int> { c in c.yield(n * 2); c.finish() } } -<< numbers
// emits 2, 4, 6
```

---

## `>=>` — Kleisli composition

Compose two functions that each return an `AsyncStream`.

```swift
let expand: @Sendable (Int) -> AsyncStream<Int> = { n in AsyncStream { c in c.yield(n); c.yield(n + 1); c.finish() } }
let doubleEach: @Sendable (Int) -> AsyncStream<Int> = { n in AsyncStream { c in c.yield(n * 2); c.finish() } }

let pipeline = expand >=> doubleEach
// pipeline(3) emits 6, 8: expand gives 3 and 4, doubleEach gives 6 and 8
```

---

## ReaderT — AsyncStream with environment

Combine `Reader` and `AsyncStream` to describe environment-dependent async sequences.

```swift
import DataStructure
import DataStructureOperators

struct Event: Sendable {
    var name: String
}

protocol EventSource: Sendable {
    func events() -> AsyncStream<Event>
}

struct LiveEventSource: EventSource {
    func events() -> AsyncStream<Event> {
        AsyncStream { c in c.yield(Event(name: "live")); c.finish() }
    }
}

struct StubEventSource: EventSource {
    var stubbed: [Event]

    func events() -> AsyncStream<Event> {
        AsyncStream { c in
            stubbed.forEach { c.yield($0) }
            c.finish()
        }
    }
}

let testEvent = Event(name: "test")

let listen = Reader<any EventSource, AsyncStream<Event>> { source in
    source.events()
}

// Wrapped in ReaderTAsyncStream, map reaches each event without touching the Reader layer
let eventNames = listen.readerT.map { $0.name }
// ReaderTAsyncStream<any EventSource, String>

// Provide the dependency at the edge (rawValue is the Reader)
let liveStream = eventNames.rawValue(LiveEventSource())

// Swap for tests
let testStream = eventNames.rawValue(StubEventSource(stubbed: [testEvent]))
```

---

## Monad Transformers

AsyncStream can be the outer layer of a transformer stack. Each stack is its own struct named
`AsyncStreamT{Inner}` wrapping an `AsyncStream`: lift with the `.asyncStreamT` property (or
`AsyncStreamTOptional(stream)`), use `map` / `flatMap` / the operators, and leave with `.rawValue`.
`mapAsyncStreamT` hands you the whole stream for anything the stack doesn't proxy.

### `AsyncStreamTOptional` (`AsyncStream<A?>`)

AsyncStream emitting optional values. `nil` elements stay `nil`.

```swift
import FP

let optStream = AsyncStream<Int?> { c in
    c.yield(1); c.yield(nil); c.yield(3); c.finish()
}.asyncStreamT   // AsyncStreamTOptional<Int>

// map: transform the inner Optional without affecting the stream layer
let optDoubled = optStream.map { $0 * 2 }
// emits Optional(2), nil, Optional(6)

// liftA2 (MaybeT ap): each left value over the whole right stream
let optA = AsyncStream<Int?> { c in c.yield(1); c.yield(nil); c.finish() }.asyncStreamT
let optB = AsyncStream<Int?> { c in c.yield(10); c.yield(20); c.finish() }.asyncStreamT
_ = AsyncStreamTOptional<Int>.liftA2(+)(optA, optB)   // emits Optional(11), Optional(21), nil

let optFns: AsyncStreamTOptional<@Sendable (Int) -> Int> =
    AsyncStream<(@Sendable (Int) -> Int)?> { c in c.yield({ $0 + 1 }); c.finish() }.asyncStreamT
_ = AsyncStreamTOptional<Int>.apply(optFns, optB)

// flatMap: each Optional element produces a new stack
let optBound = optStream.flatMap { n in
    AsyncStream<Int?> { $0.yield(Optional(n * 2)); $0.finish() }.asyncStreamT
}
// emits Optional(2), nil, Optional(6)

// Operators
_ = optStream >>- { n in AsyncStream<Int?> { $0.yield(n + 1); $0.finish() }.asyncStreamT }
_ = optA *> optB   // emits Optional(10), Optional(20), nil

@Sendable func optF(_ n: Int) -> AsyncStreamTOptional<Int> { AsyncStream<Int?> { $0.yield(n + 1); $0.finish() }.asyncStreamT }
@Sendable func optG(_ n: Int) -> AsyncStreamTOptional<Int> { AsyncStream<Int?> { $0.yield(n * 2); $0.finish() }.asyncStreamT }
_ = optF >=> optG   // AsyncStreamTOptional.kleisli(optF, optG)

_ = optBound.rawValue   // AsyncStream<Int?>
```

`AsyncStreamTOptional`, `AsyncStreamTResult` and `AsyncStreamTEither` are lawful `MaybeT` /
`ExceptT` over the stream (they conform to `MonadT`): `flatMap` is ordered concat, and `apply` /
`liftA2` / `seqRight` / `seqLeft` (`<*>`, `*>`, `<*`) are `ap` derived from `flatMap` + `map`. A
failure on the left is emitted once and never touches the right stream.

### `AsyncStreamTArray` (`AsyncStream<[A]>`)

AsyncStream emitting arrays. Inner elements are transformed as a group. Functor and applicative
only.

```swift
import FP

let arrStream = AsyncStream<[Int]> { c in
    c.yield([1, 2]); c.yield([3, 4]); c.finish()
}.asyncStreamT

_ = arrStream.map { $0 * 2 }
// emits [2, 4], [6, 8]

// liftA2: each array of arrA against every array of arrB (ap, not zip), combined with Array.liftA2
let arrA = AsyncStream<[Int]> { $0.yield([1, 2]); $0.finish() }.asyncStreamT
let arrB = AsyncStream<[Int]> { $0.yield([10, 20]); $0.finish() }.asyncStreamT
_ = AsyncStreamTArray<Int>.liftA2(+)(arrA, arrB)   // emits [11, 21, 12, 22]

_ = { $0 * 2 } <£> arrStream   // emits [2, 4], [6, 8]
```

### `AsyncStreamTResult` (`AsyncStream<Result<A, E>>`)

AsyncStream emitting Results. `.failure` elements propagate the inner error.

```swift
import FP

enum MyError: Error {
    case bad
}

let resStream = AsyncStream<Result<Int, MyError>> { c in
    c.yield(.success(5)); c.yield(.failure(.bad)); c.finish()
}.asyncStreamT

_ = resStream.map { $0 * 2 }  // emits .success(10), .failure(.bad)
_ = resStream.flatMap { n in
    AsyncStream<Result<String, MyError>> { $0.yield(.success("\(n)")); $0.finish() }.asyncStreamT
}
// emits .success("5"), .failure(.bad)
```

### `AsyncStreamTEither` (`AsyncStream<Either<L, A>>`)

AsyncStream emitting Either values.

```swift
import DataStructure

let eitherStream = AsyncStream<Either<String, Int>> { c in
    c.yield(.right(1)); c.yield(.left("err")); c.yield(.right(3)); c.finish()
}.asyncStreamT

_ = eitherStream.map { $0 * 2 }  // emits .right(2), .left("err"), .right(6)
_ = eitherStream.flatMap { n in
    AsyncStream<Either<String, Int>> { $0.yield(.right(n * 2)); $0.finish() }.asyncStreamT
}
// emits .right(2), .left("err"), .right(6)
```

### `AsyncStreamTWriter` (`AsyncStream<Writer<W, A>>`)

`WriterT w AsyncStream`. `flatMap` takes the full-stack continuation
`(A) -> AsyncStreamTWriter<W, B>`: ordered concat, each result's log is the source log followed by
the continuation's (`w1 <> w2`). `kleisli` / `>=>` / `<=<` compose such functions, and `apply` /
`liftA2` / `seqRight` / `seqLeft` (`<*>`, `*>`, `<*`) are derived from it.

```swift
import DataStructure

let steps = AsyncStream<Writer<[String], Int>> { c in c.yield(Writer(1, ["start"])); c.finish() }.asyncStreamT
_ = steps.flatMap { n in
    AsyncStream { c in c.yield(Writer(n + 1, ["inc"])); c.yield(Writer(n * 2, ["dbl"])); c.finish() }.asyncStreamT
}
// emits Writer(2, ["start", "inc"]), Writer(2, ["start", "dbl"])
```

`AsyncStreamTStateful` (`AsyncStream<Stateful<S, A>>`) is functor only. Stacks with the stream
*inside* are `ReaderTAsyncStream` (shown above), `StatefulTAsyncStream` and `WriterTAsyncStream`.
`pure` on `ReaderTAsyncStream` and `StatefulTAsyncStream` builds a fresh single-element stream on
every run, so the same stack can be run more than once.

---

## Module

```swift
import FP        // Named functions (apply, seqRight, bind…) + AsyncStreamTOptional / Array / Result
import CoreFPOperators  // Operators (<£>, <*>, >>-, >=>…) for AsyncStream and those stacks

// For AsyncStreamTEither / AsyncStreamTWriter / AsyncStreamTStateful:
import DataStructure
import DataStructureOperators

// For ReaderTAsyncStream / StatefulTAsyncStream / WriterTAsyncStream:
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
| `<*>` / `apply` | `ap` of the stream monad (`fs >>= \f -> fmap f xs`, list-like), not zip |
| `zip` | `Streaming.Prelude.zip` |

Keep the mapping loose — none of these libraries share `AsyncStream`'s exact cancellation/backpressure model, and Swift's version is scoped to structured concurrency rather than a standalone streaming DSL.

**References:**
- [`streaming`](https://hackage.haskell.org/package/streaming) — effectful, `IO`-interleaved streams closest in spirit to `AsyncStream`
