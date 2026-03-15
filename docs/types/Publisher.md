# Publisher (Combine)

Combine's `Publisher` extended with functional operators and named functions.

A `Publisher<Output, Failure>` emits a sequence of values over time and then completes or fails. The operators let you transform and chain publishers using the same patterns as `Optional`, `Result`, and `Array`.

> Requires `import Combine`. Available on macOS 13+, iOS 16+, tvOS 16+, watchOS 9+.

---

## `<£>` — Map

Apply a function to every emitted value.

```swift
let numbers: AnyPublisher<Int, Never> = [1, 2, 3].publisher.eraseToAnyPublisher()

{ $0 * 2 } <£> numbers   // emits 2, 4, 6

// Named function
AnyPublisher.fmap { $0 * 2 }(numbers)  // same
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

## `<&>` — Flipped map

Same as `<£>` with the publisher on the left.

```swift
numbers <&> { $0 * 2 }   // emits 2, 4, 6
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

## `>>-` — Bind (flatMap)

Chain publishers where each emitted value produces a new publisher. Results are merged.

```swift
let ids: AnyPublisher<Int, Never> = [1, 2, 3].publisher.eraseToAnyPublisher()

// For each id, fetch a user (returns a publisher)
ids >>- { id in fetchUser(id) }   // emits User values from all three fetches

// Named function
AnyPublisher<Int, Never>.bind(fetchUser)(ids)
```

---

## `-<<` — Flipped bind

Same as `>>-` with arguments reversed.

```swift
fetchUser -<< ids   // same as ids >>- fetchUser
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

## Module

```swift
import FP        // Named functions (fmap, apply, seqRight, bind…)
import Operators  // Operators (<£>, <*>, >>-, >=>…)

// For ReaderT + Publisher:
import Reader
import ReaderOperators
```
