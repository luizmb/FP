# AsyncSequence

`AsyncStream` extended with functional operators and named functions.

An `AsyncStream<Element>` emits values asynchronously over time. The operators let you transform and chain streams using the same patterns as `Optional`, `Result`, and `Array`.

> Requires macOS 10.15+, iOS 13.0+. Concurrency context (`async`/`await`) required at the call site.

---

## `<£>` — Map

Apply an async function to every emitted element.

```swift
let numbers = AsyncStream<Int> { c in c.yield(1); c.yield(2); c.yield(3); c.finish() }

let doubled = { (n: Int) async -> Int in n * 2 } <£> numbers
// emits 2, 4, 6

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

## `<&>` — Flipped map

Same as `<£>` with the stream on the left.

```swift
numbers <&> { (n: Int) async -> Int in n * 2 }   // emits 2, 4, 6
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

## `>>-` — Bind (flatMap)

For each emitted element, produce a new async sequence and flatten the results.

```swift
numbers >>- { n in AsyncStream<Int> { c in c.yield(n); c.yield(n * 10); c.finish() } }
// emits 1, 10, 2, 20, 3, 30
```

---

## `-<<` — Flipped bind

Same as `>>-` with arguments reversed.

```swift
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
import ReaderConcurrencyFP
import ReaderConcurrencyOperators

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

## Module

```swift
import ConcurrencyFP        // Named functions (apply, seqRight, bind…)
import ConcurrencyOperators  // Operators (<£>, <*>, >>-, >=>…)

// For ReaderT + AsyncStream:
import ReaderConcurrencyFP
import ReaderConcurrencyOperators
```
