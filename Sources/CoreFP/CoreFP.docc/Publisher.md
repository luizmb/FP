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
import Combine

let numbers: AnyPublisher<Int, Never> = [1, 2, 3].publisher.eraseToAnyPublisher()

_ = { $0 * 2 } <£> numbers   // emits 2, 4, 6
_ = numbers <&> { $0 * 2 }   // emits 2, 4, 6

// Named function
_ = AnyPublisher<Int, Never>.fmap { $0 * 2 }(numbers)
_ = numbers.map { $0 * 2 }.eraseToAnyPublisher()
```

---

## `£>` and `<£` — Replace

Replace every emitted value with a constant.

```swift
_ = numbers £> "tick"    // emits "tick", "tick", "tick"
_ = "tick" <£ numbers    // same

// Named function
_ = numbers.replaceOutput("tick")
```

---

## `<*>` — Apply

`ap` derived from the ordered-concat bind: for each function, in order, map it over the whole value stream. The value publisher is subscribed once per function.

```swift
let adders: [@Sendable (Int) -> Int] = [{ $0 + 1 }, { $0 * 10 }]
let fns: AnyPublisher<@Sendable (Int) -> Int, Never> = adders.publisher.eraseToAnyPublisher()

_ = fns <*> numbers   // emits 2, 3, 4, 10, 20, 30

// Named functions
_ = AnyPublisher<Int, Never>.apply(fns, numbers)
_ = AnyPublisher<Int, Never>.liftA2 { (a: Int, b: Int) in a + b }(numbers, numbers)
```

---

## `*>` and `<*` — Sequence

Derived from bind too: the right publisher runs once for every value of the left one.

```swift
let letters: AnyPublisher<String, Never> = ["a", "b"].publisher.eraseToAnyPublisher()

_ = numbers *> letters   // emits "a", "b", "a", "b", "a", "b"
_ = numbers <* letters   // emits 1, 1, 2, 2, 3, 3

// Named functions
_ = AnyPublisher<String, Never>.seqRight(numbers, letters)
_ = AnyPublisher<Int, Never>.seqLeft(numbers, letters)
```

---

## `zip` — Pairwise combination

`zip` pairs values by position, like Haskell's `zip` for lists. It is a named function, not the applicative.

```swift
_ = AnyPublisher<(Int, String), Never>.zip(numbers, letters)   // emits (1, "a"), (2, "b")
```

---

## `>>-` and `-<<` — Bind (ordered concat)

Chain publishers where each emitted value produces a new publisher. `>>-` puts the publisher on the left; `-<<` puts the function on the left. Inner publishers run one at a time, in upstream order, and every value of each one is emitted before the next starts. Upstream values are never dropped, even from sources that ignore demand such as `PassthroughSubject`.

```swift
struct User: Codable, Sendable {
    var id: Int
    var name: String
}

struct Profile: Sendable {
    var bio: String
}

@Sendable func fetchUser(_ id: Int) -> AnyPublisher<User, Never> {
    Just(User(id: id, name: "user \(id)")).eraseToAnyPublisher()
}

let ids: AnyPublisher<Int, Never> = [1, 2, 3].publisher.eraseToAnyPublisher()

_ = ids >>- { id in fetchUser(id) }   // the user for 1, then for 2, then for 3
_ = fetchUser -<< ids                 // same

// Named functions
_ = AnyPublisher<Int, Never>.bind(fetchUser)(ids)
_ = ids.concatMap(fetchUser)
```

Use Combine's `flatMap` when you want the inner publishers merged concurrently, or `map(fetchUser).switchToLatest()` to keep only the latest one.

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Publisher`.

```swift
@Sendable func fetchProfile(_ user: User) -> AnyPublisher<Profile, Never> {
    Just(Profile(bio: "bio of \(user.name)")).eraseToAnyPublisher()
}

let fetchUserProfile = fetchUser >=> fetchProfile
_ = fetchUserProfile(42)  // Publisher<Profile, Never>, fetches the user then the profile (ordered concat)

// Named function
_ = AnyPublisher<User, Never>.kleisli(fetchUser, fetchProfile)(42)
```

---

## ReaderT — Publisher with environment

Combine `Reader` and `Publisher` to describe environment-dependent reactive computations. A typical use case is injecting a networking protocol so the real implementation and a test mock are swapped at the call site without changing any logic.

```swift
import DataStructure
import DataStructureOperators

protocol HTTPClient: Sendable {
    func get(_ path: String) -> AnyPublisher<Data, Error>
}

struct LiveHTTPClient: HTTPClient {
    func get(_ path: String) -> AnyPublisher<Data, Error> {
        URLSession.shared.dataTaskPublisher(for: URL(string: "https://example.com" + path)!)
            .map(\.data)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

struct StubHTTPClient: HTTPClient {
    var response: Data

    func get(_ path: String) -> AnyPublisher<Data, Error> {
        Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

let testData = Data("[]".utf8)

// Describe the computation — no concrete session, no global state
let fetchUsers = Reader<any HTTPClient, AnyPublisher<[User], Error>> { client in
    client.get("/users")
        .decode(type: [User].self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
}

// Wrapped in ReaderTPublisher, map reaches the emitted values without touching the Reader layer
let userNames = fetchUsers.readerT.map { users in users.map { $0.name } }
// ReaderTPublisher<any HTTPClient, Error, [String]>

// The operators work through both layers too
_ = { users in users.map { $0.name } } <£> fetchUsers.readerT

// Provide the real dependency at the edge (rawValue is the Reader)
let publisher = userNames.rawValue(LiveHTTPClient())
// publisher is any Publisher<[String], Error>

// Swap for tests, no mocking framework needed
let testPublisher = userNames.rawValue(StubHTTPClient(response: testData))
```

---

## Monad Transformers

Publisher can be the outer layer of a transformer stack, threading another monad's effects through
its emission. Each stack is its own struct named `PublisherT{Inner}` wrapping an `AnyPublisher`:
lift any publisher with the `.publisherT` property (or `PublisherTOptional(anyPublisher)`), use `map` /
`flatMap` / the operators, and leave with `.rawValue` (an `AnyPublisher`). For Combine operators the
stack doesn't proxy (`receive(on:)`, `buffer`, …) use the escape hatch `mapPublisherT`.

### `PublisherTOptional` (`AnyPublisher<A?, Failure>`)

Publisher emitting optional values. Inner `nil` elements stay `nil`.

```swift
import FP

let optPub: PublisherTOptional<Never, Int> = ([1, nil, 3] as [Int?]).publisher.publisherT

// map: transform the inner Optional without affecting the Publisher layer
let optDoubled = optPub.map { $0 * 2 }
// emits Optional(2), nil, Optional(6)

// liftA2 (MaybeT ap): for each element of optA, the whole of optB runs
let optA: PublisherTOptional<Never, Int> = ([1, nil] as [Int?]).publisher.publisherT
let optB: PublisherTOptional<Never, Int> = ([10, 20] as [Int?]).publisher.publisherT
_ = PublisherTOptional<Never, Int>.liftA2(+)(optA, optB)
// emits Optional(11), Optional(21), nil  (a nil short-circuits that element once)

// flatMap: each Optional element produces a new stack
_ = optPub.flatMap { n in Just(Optional(n * 2)).publisherT }
// emits Optional(2), nil, Optional(6)

// Operators
_ = optPub >>- { n in Just(Optional(n + 1)).publisherT }   // ordered concat, like the base bind

// Escape hatch: any Combine operator on the whole AnyPublisher<Int?, Never>
_ = optPub.mapPublisherT { $0.receive(on: DispatchQueue.main).eraseToAnyPublisher() }

optDoubled.rawValue   // AnyPublisher<Int?, Never>
```

`PublisherTOptional`, `PublisherTResult` and `PublisherTEither` are lawful `MaybeT` / `ExceptT`
stacks over the stream (they conform to `MonadT`): `flatMap` uses the ordered-concat bind,
`kleisli` / `>=>` compose, and `apply` / `<*>`, `liftA2`, `*>` and `<*` are `ap` derived from
`flatMap` and `map`.

### `PublisherTArray` (`AnyPublisher<[A], Failure>`)

Publisher emitting arrays. Inner elements are transformed as a group. Functor and applicative only
(see "Why some combos lack a Monad" in the Monad Transformers article).

```swift
import FP

let arrPub: PublisherTArray<Never, Int> = [[1, 2], [3, 4]].publisher.publisherT

_ = arrPub.map { $0 * 2 }   // emits [2, 4], [6, 8]

// liftA2: each array of arrA against every array of arrB (ap, not zip), combined with Array.liftA2
let arrA: PublisherTArray<Never, Int> = Just([1, 2]).publisherT
let arrB: PublisherTArray<Never, Int> = Just([10, 20]).publisherT
_ = PublisherTArray<Never, Int>.liftA2(+)(arrA, arrB)   // emits [11, 21, 12, 22]

// Operators
_ = { $0 * 2 } <£> arrPub   // emits [2, 4], [6, 8]
```

### `PublisherTResult` (`AnyPublisher<Result<A, E>, Failure>`)

Publisher emitting Results. `.failure` elements propagate the inner error.

```swift
import FP

enum MyError: Error {
    case bad
}

let resPub: PublisherTResult<Never, MyError, Int> =
    [Result<Int, MyError>.success(5), .failure(.bad)].publisher.publisherT

_ = resPub.map { $0 * 2 }  // emits .success(10), .failure(.bad)
_ = resPub.flatMap { n in Just(Result<String, MyError>.success("\(n)")).publisherT }
// emits .success("5"), .failure(.bad)
```

### `PublisherTEither` (`AnyPublisher<Either<L, A>, Failure>`)

Publisher emitting Either values.

```swift
import DataStructure

let eitherPub: PublisherTEither<Never, String, Int> =
    [Either.right(1), .left("err"), .right(3)].publisher.publisherT

_ = eitherPub.map { $0 * 2 }  // emits .right(2), .left("err"), .right(6)
_ = eitherPub.flatMap { n in Just(Either<String, Int>.right(n * 2)).publisherT }
// emits .right(2), .left("err"), .right(6)
```

### `PublisherTWriter` (`AnyPublisher<Writer<W, A>, Failure>`)

`WriterT w` over the stream. `flatMap` takes the whole stack as its continuation, concatenates the
inner streams in order and combines every log as `outer <> inner`.

```swift
import DataStructure

let writerPub: PublisherTWriter<Never, [String], Int> = Just(Writer(2, ["start"])).publisherT

_ = writerPub.flatMap { n in [Writer(n, ["a"]), Writer(n * 10, ["b"])].publisher.publisherT }
// emits Writer(2, ["start", "a"]), Writer(20, ["start", "b"])

// Operators (DataStructureOperators): >>-, -<<, >=>, <=<, <*>, *>, <*
```

`PublisherTStateful` (`AnyPublisher<Stateful<S, A>, Failure>`) is functor and applicative only.
Stacks with the Publisher *inside* are `ReaderTPublisher` (shown above), `StatefulTPublisher` and
`WriterTPublisher`.

---

## Module

```swift
import FP        // Named functions (fmap, apply, seqRight, bind…) + PublisherTOptional / Array / Result
import CoreFPOperators  // Operators (<£>, <*>, >>-, >=>…) for Publisher and those stacks

// For PublisherTEither / PublisherTWriter / PublisherTStateful:
import DataStructure
import DataStructureOperators

// For ReaderTPublisher / StatefulTPublisher / WriterTPublisher:
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
