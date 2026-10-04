# ``Combine/Publisher``

Combine's `Publisher` extended with functional operators and named functions.

A `Publisher<Output, Failure>` emits a sequence of values over time and then completes or fails. The operators let you transform and chain publishers using the same patterns as `Optional`, `Result`, and `Array`.

The monad follows Haskell stream semantics (as in `pipes`, `conduit` or `fs2`): bind is **ordered concatenation**. Each inner publisher runs to completion, in upstream order, before the next one starts, and no upstream value is dropped (values that arrive while an inner publisher is still running are buffered). The applicative (`<*>`, `liftA2`, `*>`, `<*`) is derived from that bind, so it behaves like the `Array` applicative: cartesian and sequential. Pairwise combination is `zip`.

When you want Combine's other flattening strategies, call them directly: `flatMap` merges inner publishers concurrently, `map(_:).switchToLatest()` keeps only the latest one.

> Requires `import Combine`. Available on macOS 13+, iOS 16+, tvOS 16+, watchOS 9+.

---

## `<£>` and `<&>` — Map

Apply a function to every emitted value. `<£>` puts the function on the left; `<&>` puts the publisher on the left.

```swift
let numbers: AnyPublisher<Int, Never> = [1, 2, 3].publisher.eraseToAnyPublisher()

{ $0 * 2 } <£> numbers   // emits 2, 4, 6
numbers <&> { $0 * 2 }   // emits 2, 4, 6

// Named function
AnyPublisher.fmap { $0 * 2 }(numbers)
numbers.map { $0 * 2 }.eraseToAnyPublisher()
```

---

## `£>` and `<£` — Replace

Replace every emitted value with a constant.

```swift
numbers £> "tick"    // emits "tick", "tick", "tick"
"tick" <£ numbers    // same

// Named function
numbers.replaceOutput("tick")
```

---

## `<*>` — Apply

`ap` derived from the ordered-concat bind: for each function, in order, map it over the whole value stream. The value publisher is subscribed once per function.

```swift
let fns: AnyPublisher<@Sendable (Int) -> Int, Never> = [{ $0 + 1 }, { $0 * 10 }]
    .publisher.eraseToAnyPublisher()

fns <*> numbers   // emits 2, 3, 4, 10, 20, 30

// Named functions
AnyPublisher.apply(fns, numbers)
AnyPublisher<Int, Never>.liftA2 { (a: Int, b: Int) in a + b }(numbers, numbers)
```

---

## `*>` and `<*` — Sequence

Derived from bind too: the right publisher runs once for every value of the left one.

```swift
let letters: AnyPublisher<String, Never> = ["a", "b"].publisher.eraseToAnyPublisher()

numbers *> letters   // emits "a", "b", "a", "b", "a", "b"
numbers <* letters   // emits 1, 1, 2, 2, 3, 3

// Named functions
AnyPublisher.seqRight(numbers, letters)
AnyPublisher.seqLeft(numbers, letters)
```

---

## `zip` — Pairwise combination

`zip` pairs values by position, like Haskell's `zip` for lists. It is a named function, not the applicative.

```swift
AnyPublisher<(Int, String), Never>.zip(numbers, letters)   // emits (1, "a"), (2, "b")
```

---

## `>>-` and `-<<` — Bind (ordered concat)

Chain publishers where each emitted value produces a new publisher. `>>-` puts the publisher on the left; `-<<` puts the function on the left. Inner publishers run one at a time, in upstream order, and every value of each one is emitted before the next starts. Upstream values are never dropped, even from sources that ignore demand such as `PassthroughSubject`.

```swift
let ids: AnyPublisher<Int, Never> = [1, 2, 3].publisher.eraseToAnyPublisher()

ids >>- { id in fetchUser(id) }   // the user for 1, then for 2, then for 3
fetchUser -<< ids                 // same

// Named functions
AnyPublisher<Int, Never>.bind(fetchUser)(ids)
ids.concatMap(fetchUser)
```

Use Combine's `flatMap` when you want the inner publishers merged concurrently, or `map(fetchUser).switchToLatest()` to keep only the latest one.

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Publisher`.

```swift
let fetchUser:    (Int)  -> AnyPublisher<User, Error>   = { ... }
let fetchProfile: (User) -> AnyPublisher<Profile, Error> = { ... }

let fetchUserProfile = fetchUser >=> fetchProfile
fetchUserProfile(42)  // Publisher<Profile, Error> — fetches user then profile (ordered concat)

// Named function
AnyPublisher.kleisli(fetchUser, fetchProfile)(42)
```

---

## ReaderT — Publisher with environment

Combine `Reader` and `Publisher` to describe environment-dependent reactive computations. A typical use case is injecting a networking protocol so the real implementation and a test mock are swapped at the call site without changing any logic.

```swift
import DataStructure
import DataStructureOperators

protocol HTTPClient {
    func get(_ path: String) -> AnyPublisher<Data, Error>
}

// Describe the computation — no concrete session, no global state
let fetchUsers = Reader<any HTTPClient, AnyPublisher<[User], Error>> { client in
    client.get("/users")
        .decode(type: [User].self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
}

// mapT maps inside the Publisher without touching the Reader layer
let userNames = fetchUsers.mapT { $0.map(\.name) }
// Reader<any HTTPClient, AnyPublisher<[String], Error>>

// All operators work through both layers
{ $0.map(\.name) } <£> fetchUsers
// Reader<any HTTPClient, AnyPublisher<[String], Error>>

// Provide the real dependency at the edge
let publisher = userNames(LiveHTTPClient())
// publisher is AnyPublisher<[String], Error>

// Swap for tests — no mocking framework needed
let testPublisher = userNames(StubHTTPClient(response: testData))
```

---

## Monad Transformers

Publisher can be the outer layer of a transformer stack, threading another monad's effects through its emission. The transformer name is `PublisherT{Inner}`.

### `PublisherTOptional` — `AnyPublisher<A?, E>`

Publisher emitting optional values. Inner `nil` elements stay `nil`.

```swift
import FP

let pub: AnyPublisher<Int?, Never> = [1, nil, 3].publisher
    .map { $0 as Int? }.eraseToAnyPublisher()

// mapT — transform inner Optional without affecting the Publisher layer
let doubled = mapTPublisherOptional({ $0 * 2 }, pub)
// emits Optional(2), nil, Optional(6)

// liftA2 — derived from flatMapT: for each element of pubA, the whole of pubB runs
let pubA: AnyPublisher<Int?, Never> = [1, nil].publisher.eraseToAnyPublisher()
let pubB: AnyPublisher<Int?, Never> = [10, 20].publisher.eraseToAnyPublisher()
liftA2PublisherOptional(+)(pubA, pubB)
// emits Optional(11), Optional(21), nil  (a nil short-circuits that element once)

// flatMapT — each Optional element produces a new Publisher<B?, E>
flatMapTPublisherOptional(pub) { n in
    Just(Optional(n * 2)).setFailureType(to: Never.self).eraseToAnyPublisher()
}
// emits Optional(2), nil, Optional(6)

// Operators
{ $0 * 2 } <£^> pub   // emits Optional(2), nil, Optional(6)
pub >>- { n in Just(Optional(n + 1)).eraseToAnyPublisher() }   // ordered concat, like the base bind
```

`PublisherTOptional`, `PublisherTResult` and `PublisherTEither` are lawful `MaybeT` / `ExceptT` stacks over the stream: `flatMapT` uses the ordered-concat bind, `kleisliT` / `>=>` compose, and `apply` / `<*>`, `liftA2`, `*>` and `<*` are derived from `flatMapT` and `mapT`.

### `PublisherTArray` — `AnyPublisher<[A], E>`

Publisher emitting arrays. Inner elements are transformed as a group.

```swift
import FP

let pub: AnyPublisher<[Int], Never> = [[1, 2], [3, 4]].publisher.eraseToAnyPublisher()

mapTPublisherArray({ $0 * 2 }, pub)   // emits [2, 4], [6, 8]

// liftA2 — zip two publishers and combine arrays with Array.liftA2
let pubA: AnyPublisher<[Int], Never> = Just([1, 2]).eraseToAnyPublisher()
let pubB: AnyPublisher<[Int], Never> = Just([10, 20]).eraseToAnyPublisher()
liftA2PublisherArray(+)(pubA, pubB)   // emits [11, 21, 12, 22]

// Operators
{ $0 * 2 } <£> pub   // emits [2, 4], [6, 8]
```

### `PublisherTResult` — `AnyPublisher<Result<A,E2>, E>`

Publisher emitting Results. `.failure` elements propagate the inner error.

```swift
import FP

let pub: AnyPublisher<Result<Int, MyError>, Never> =
    [.success(5), .failure(.bad)].publisher.eraseToAnyPublisher()

mapTPublisherResult({ $0 * 2 }, pub)  // emits .success(10), .failure(.bad)
flatMapTPublisherResult(pub) { n in
    Just(Result<String, MyError>.success("\(n)")).eraseToAnyPublisher()
}
// emits .success("5"), .failure(.bad)
```

### `PublisherTEither` — `AnyPublisher<Either<L,A>, E>`

Publisher emitting Either values.

```swift
import DataStructure

let pub: AnyPublisher<Either<String, Int>, Never> =
    [Either.right(1), .left("err"), .right(3)].publisher.eraseToAnyPublisher()

mapTPublisherEither({ $0 * 2 }, pub)  // emits .right(2), .left("err"), .right(6)
flatMapTPublisherEither(pub) { n in
    Just(Either<String, Int>.right(n * 2)).eraseToAnyPublisher()
}
// emits .right(2), .left("err"), .right(6)

// Operators (DataStructureOperators)
{ $0 * 2 } <£^> pub
```

### `PublisherTWriter` — `AnyPublisher<Writer<W, A>, E>`

`WriterT w` over the stream. The bind takes the whole stack as its continuation, concatenates the inner streams in order and combines every log as `outer <> inner`.

```swift
import DataStructure

let pub: AnyPublisher<Writer<[String], Int>, Never> =
    Just(Writer(2, ["start"])).eraseToAnyPublisher()

pub.flatMapT { n in
    [Writer(n, ["a"]), Writer(n * 10, ["b"])].publisher.eraseToAnyPublisher()
}
// emits Writer(2, ["start", "a"]), Writer(20, ["start", "b"])

// Operators (DataStructureOperators): >>-, -<<, >=>, <=<, <*>, *>, <*
```

---

## Module

```swift
import FP        // Named functions (fmap, apply, seqRight, bind…) + PublisherT stacks
import CoreFPOperators  // Operators (<£>, <*>, >>-, >=>…) for Publisher and PublisherT stacks

// For PublisherTEither:
import DataStructure
import DataStructureOperators

// For ReaderT + Publisher:
import DataStructure
import DataStructureOperators
```

---

## For Haskell developers

Combine's `Publisher<Output, Failure>` has no equivalent in `base` — it's a reactive-streams abstraction (push-based, multi-subscriber, with cancellation and backpressure) closer to FRP than to a plain lazy list. The closest well-known Haskell prior art is an FRP library like `reactive-banana` or `reflex`, which model time-varying, event-driven values the same way Combine models "a sequence of values over time that completes or fails." A looser, non-FRP-flavored alternative is `pipes`/`conduit`, the same effectful-streaming libraries referenced in the AsyncSequence article, since a `Publisher` can also just be read as "a lazy stream of values interleaved with an effect."

| This library | Rough Haskell parallel |
|---|---|
| `AnyPublisher<Output, Failure>` | an FRP `Event`/`Behavior` (`reactive-banana`, `reflex`) or an effectful stream (`pipes`/`conduit`) |
| `<£>` / `.map` | `fmap` over the FRP library's `Event`/`Behavior` functor |
| `>>-` / `.bind` / `.concatMap` | streaming-library monadic bind (`pipes`/`conduit`/`fs2`): ordered concat |
| `<*>` / `.apply` | `ap` for streams (cartesian, like the list applicative) |
| `.zip` | `zip` for lists (pairwise) |
| `>=>` (Kleisli) | Kleisli composition of functions returning `Event`/`Behavior` |

Treat this as directional inspiration, not a literal type correspondence — Combine's cold/hot publisher semantics and demand-driven backpressure don't line up cleanly with any single Haskell library.

**References:**
- [`reactive-banana`](https://hackage.haskell.org/package/reactive-banana) — the closest well-known FRP analog to Combine's reactive semantics
