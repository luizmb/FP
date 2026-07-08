# Publisher (Combine)

Combine's `Publisher` extended with functional operators and named functions.

A `Publisher<Output, Failure>` emits a sequence of values over time and then completes or fails. The operators let you transform and chain publishers using the same patterns as `Optional`, `Result`, and `Array`.

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

Zip a publisher of functions with a publisher of values, applying each pair.

```swift
let fns: AnyPublisher<(Int) -> Int, Never> = [{ $0 + 1 }, { $0 * 10 }]
    .publisher.eraseToAnyPublisher()

fns <*> numbers   // emits 2 (1+1), 20 (2*10), then completes when either finishes

// Named function
AnyPublisher.apply(fns, numbers)
```

---

## `*>` and `<*` — Sequence

Zip two publishers, keeping only one side's values.

```swift
let letters: AnyPublisher<String, Never> = ["a", "b", "c"].publisher.eraseToAnyPublisher()

numbers *> letters   // emits "a", "b", "c"  (numbers run but values discarded)
numbers <* letters   // emits 1, 2, 3         (letters run but values discarded)

// Named functions
AnyPublisher.seqRight(numbers, letters)
AnyPublisher.seqLeft(numbers, letters)
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain publishers where each emitted value produces a new publisher. `>>-` puts the publisher on the left; `-<<` puts the function on the left.

```swift
let ids: AnyPublisher<Int, Never> = [1, 2, 3].publisher.eraseToAnyPublisher()

ids >>- { id in fetchUser(id) }   // emits User values from all three fetches
fetchUser -<< ids                 // same

// Named function
AnyPublisher<Int, Never>.bind(fetchUser)(ids)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Publisher`.

```swift
let fetchUser:    (Int)  -> AnyPublisher<User, Error>   = { ... }
let fetchProfile: (User) -> AnyPublisher<Profile, Error> = { ... }

let fetchUserProfile = fetchUser >=> fetchProfile
fetchUserProfile(42)  // Publisher<Profile, Error> — fetches user then profile

// Named function
AnyPublisher.kleisli(fetchUser, fetchProfile)(42)
```

---

## ReaderT — Publisher with environment

Combine `Reader` and `Publisher` to describe environment-dependent reactive computations. A typical use case is injecting a networking protocol so the real implementation and a test mock are swapped at the call site without changing any logic.

```swift
import Reader
import ReaderOperators

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

// liftA2 — zip two publishers and combine their inner Optional values
let pubA: AnyPublisher<Int?, Never> = Just(Optional(3)).eraseToAnyPublisher()
let pubB: AnyPublisher<Int?, Never> = Just(Optional(4)).eraseToAnyPublisher()
liftA2PublisherOptional(+)(pubA, pubB)
// emits Optional(7)

// flatMapT — each Optional element produces a new Publisher<B?, E>
flatMapTPublisherOptional(pub) { n in
    Just(Optional(n * 2)).setFailureType(to: Never.self).eraseToAnyPublisher()
}
// emits Optional(2), nil, Optional(6)

// Operators
{ $0 * 2 } <£> pub   // emits Optional(2), nil, Optional(6)
pub >>- { n in Just(n.map { $0 + 1 }).setFailureType(to: Never.self).eraseToAnyPublisher() }
```

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
import Either

let pub: AnyPublisher<Either<String, Int>, Never> =
    [Either.right(1), .left("err"), .right(3)].publisher.eraseToAnyPublisher()

mapTPublisherEither({ $0 * 2 }, pub)  // emits .right(2), .left("err"), .right(6)
flatMapTPublisherEither(pub) { n in
    Just(Either<String, Int>.right(n * 2)).eraseToAnyPublisher()
}
// emits .right(2), .left("err"), .right(6)

// Operators (EitherOperators)
{ $0 * 2 } <£> pub
```

---

## Module

```swift
import FP        // Named functions (fmap, apply, seqRight, bind…) + PublisherT stacks
import Operators  // Operators (<£>, <*>, >>-, >=>…) for Publisher and PublisherT stacks

// For PublisherTEither:
import Either
import EitherOperators

// For ReaderT + Publisher:
import Reader
import ReaderOperators
```

---

## For Haskell developers

Combine's `Publisher<Output, Failure>` has no equivalent in `base` — it's a reactive-streams abstraction (push-based, multi-subscriber, with cancellation and backpressure) closer to FRP than to a plain lazy list. The closest well-known Haskell prior art is an FRP library like `reactive-banana` or `reflex`, which model time-varying, event-driven values the same way Combine models "a sequence of values over time that completes or fails." A looser, non-FRP-flavored alternative is `pipes`/`conduit`, the same effectful-streaming libraries referenced in the AsyncSequence article, since a `Publisher` can also just be read as "a lazy stream of values interleaved with an effect."

| This library | Rough Haskell parallel |
|---|---|
| `AnyPublisher<Output, Failure>` | an FRP `Event`/`Behavior` (`reactive-banana`, `reflex`) or an effectful stream (`pipes`/`conduit`) |
| `<£>` / `.map` | `fmap` over the FRP library's `Event`/`Behavior` functor |
| `>>-` / `.flatMap` (via `.bind`) | the FRP library's event-switching bind, or streaming-library monadic bind |
| `>=>` (Kleisli) | Kleisli composition of functions returning `Event`/`Behavior` |

Treat this as directional inspiration, not a literal type correspondence — Combine's cold/hot publisher semantics and demand-driven backpressure don't line up cleanly with any single Haskell library.

**References:**
- [`reactive-banana`](https://hackage.haskell.org/package/reactive-banana) — the closest well-known FRP analog to Combine's reactive semantics
