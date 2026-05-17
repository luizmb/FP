# Loading

`Loading<Success, Failure>` is a four-state lifecycle enum for async operations: `.idle`, `.loading(previous:)`, `.loaded(Success)`, and `.failed(Failure, previous:)`. The `previous` payload on `.loading` and `.failed` carries the last successful value so UIs can keep displaying stale data while a refresh is in flight or after an error.

```swift
import DataStructure

public enum Loading<Success: Sendable, Failure: Error & Sendable>: Sendable {
    case idle
    case loading(previous: Success?)
    case loaded(Success)
    case failed(Failure, previous: Success?)
}
```

`Loading` is a `Functor` (``map``), a binary applicative via ``zip``, a `Monad` (``flatMap``), and supports error recovery via ``catch``. Operator forms — `<£>`, `<&>`, `£>`, `<£`, `>>-`, `-<<`, `>=>`, `<=<` — live in `DataStructureOperators`.

---

## Construction & state transitions

The state machine is driven by `Result`. The three transition helpers preserve `loadedOrPrevious` so stale data is never thrown away accidentally.

```swift
var state: Loading<[Movie], NetworkError> = .idle

// Kick off a fetch — carries `loadedOrPrevious` into `.loading`.
state = state.startLoading()
// .loading(previous: nil)

// Resolve to a Result — `.loaded` on success, `.failed(_, previous:)` on failure.
state = state.applying(.success([movie1, movie2]))
// .loaded([movie1, movie2])

state = state.startLoading()
// .loading(previous: [movie1, movie2])  — stale data preserved during refresh

state = state.applying(.failure(.timeout))
// .failed(.timeout, previous: [movie1, movie2])

// Or build a fresh Loading from a Result (no prior context).
let fresh = Loading<[Movie], NetworkError>.from(.success([]))
// .loaded([])
```

### `loadedOrPrevious`

Returns the loaded value, or the most recent `previous`. `nil` for `.idle` and for in-flight / failed states that never produced data.

```swift
Loading<Int, MyError>.idle.loadedOrPrevious                                // nil
Loading<Int, MyError>.loading(previous: nil).loadedOrPrevious              // nil
Loading<Int, MyError>.loading(previous: 42).loadedOrPrevious               // 42
Loading<Int, MyError>.loaded(7).loadedOrPrevious                           // 7
Loading<Int, MyError>.failed(.network, previous: 3).loadedOrPrevious       // 3
```

---

## `<£>` and `<&>` — Map

Transform the `Success` channel. `previous` values in `.loading` and `.failed` are mapped too, so stale data stays consistent. `.idle` and the `Failure` channel pass through unchanged.

```swift
{ $0 * 2 } <£> Loading<Int, E>.loaded(5)                  // .loaded(10)
{ $0 * 2 } <£> Loading<Int, E>.loading(previous: 3)       // .loading(previous: 6)
{ $0 * 2 } <£> Loading<Int, E>.failed(.x, previous: 4)    // .failed(.x, previous: 8)
{ $0 * 2 } <£> Loading<Int, E>.idle                       // .idle

Loading.loaded(5) <&> { $0 * 2 }                          // .loaded(10)

// Named functions
Loading<Int, E>.fmap { $0 * 2 }(.loaded(5))   // .loaded(10)
Loading.loaded(5).map { $0 * 2 }              // .loaded(10)
```

---

## `£>` and `<£` — Replace

Replace the loaded value with a constant.

```swift
Loading<Int, E>.loaded(42) £> "done"                      // .loaded("done")
Loading<Int, E>.failed(.x, previous: 7) £> "done"         // .failed(.x, previous: "done")
"done" <£ Loading<Int, E>.loaded(42)                      // .loaded("done")
```

---

## `zip` — Combine two Loadings

Combine two `Loading` values that share a `Failure` type into a `Loading` of the pair. Precedence — first match wins:

1. Either side `.failed` → `.failed` (first error, pair of `loadedOrPrevious` when both have one).
2. Either side `.idle` → `.idle`.
3. Either side `.loading` → `.loading` (pair of `loadedOrPrevious` when both have one).
4. Both `.loaded` → `.loaded(pair)`.

```swift
typealias L<A: Sendable> = Loading<A, NetworkError>

L<(Int, String)>.zip(.loaded(1), .loaded("a"))
// .loaded((1, "a"))

L<(Int, String)>.zip(.idle, .loaded("a"))
// .idle

L<(Int, String)>.zip(.loading(previous: 1), .loaded("a"))
// .loading(previous: Optional((1, "a")))

L<(Int, String)>.zip(.failed(.network, previous: 1), .loaded("a"))
// .failed(.network, previous: Optional((1, "a")))
```

> `Loading` doesn't expose `<*>` / `pure` because there is no canonical way to wrap a single value as `.idle` / `.loading` / `.failed`. Use ``zip`` when you need applicative-style combination.

---

## `>>-`, `-<<`, `>=>`, `<=<` — Bind & Kleisli

Chain operations that each return a `Loading`. `.loaded` is the only state that actually invokes the continuation; the others pass through, with `previous` mapped through the function so stale-data invariants survive the chain.

```swift
func authorize(_ id: Int) -> Loading<Session, AuthError> { ... }
func fetchProfile(_ session: Session) -> Loading<Profile, AuthError> { ... }

let result = Loading<Int, AuthError>.loaded(42)
    >>- authorize
    >>- fetchProfile

// Function on the left
let result2 = fetchProfile -<< authorize -<< .loaded(42)

// Kleisli composition (build the pipeline once, run later)
let pipeline = authorize >=> fetchProfile
pipeline(42)                       // Loading<Profile, AuthError>

let pipelineBack = fetchProfile <=< authorize
pipelineBack(42)                   // Loading<Profile, AuthError>

// Named functions
Loading.loaded(42).flatMap(authorize)
Loading<Int, AuthError>.kleisli(authorize, fetchProfile)(42)
```

---

## `catch` — Recover from failure

`.failed` can be transformed into any other `Loading`. The other cases pass through.

```swift
let recovered = Loading<Int, NetworkError>
    .failed(.timeout, previous: 7)
    .catch { _ in .loaded(0) }
// .loaded(0)

// Map one error into another
Loading<Int, NetworkError>
    .failed(.timeout, previous: nil)
    .catch { _ in .failed(.cancelled, previous: nil) }
// .failed(.cancelled, previous: nil)

// Non-failed cases pass through
Loading<Int, NetworkError>.idle.catch { _ in .loaded(0) }              // .idle
Loading<Int, NetworkError>.loading(previous: 7).catch { _ in .loaded(0) }
// .loading(previous: 7)
```

---

## Prisms, `cases`, and `is(_:)`

`Loading` ships hand-written equivalents of what FP's `@Prisms` macro generates — the macro itself can't be applied because `Loading` is generic and Swift forbids `static let` stored properties in generic contexts; the surface is identical for callers.

### `Loading.prism.<case>` — `CoreFP.Prism`

```swift
Loading<Int, E>.prism.idle    // Prism<Loading<Int, E>, Void>
Loading<Int, E>.prism.loading // Prism<Loading<Int, E>, Int?>
Loading<Int, E>.prism.loaded  // Prism<Loading<Int, E>, Int>
Loading<Int, E>.prism.failed  // Prism<Loading<Int, E>, (E, Int?)>

Loading.prism.loaded.preview(.loaded(7))                    // 7
Loading.prism.loaded.preview(.idle)                          // nil
Loading.prism.loaded.review(42)                              // .loaded(42)
Loading.prism.loaded.set(.loaded(1), 99)                     // .loaded(99)
Loading.prism.loaded.over({ $0 * 2 })(.loaded(5))            // .loaded(10)
```

### Computed accessors

Each case has a matching computed property: `.idle`, `.loading`, `.loaded`, `.failed`. They wrap `prism.<case>.preview(self)`, so they return optionals — note that `.loading` is a double-optional because the focus type is `Success?`.

```swift
let state: Loading<Int, E> = .loaded(42)
state.loaded                    // Optional(42)
state.idle                       // nil
state.loading                    // nil
state.failed                     // nil

let inFlight: Loading<Int, E> = .loading(previous: 7)
inFlight.loading                 // Optional(Optional(7))  — double optional
inFlight.loading ?? nil          // Optional(7)
```

### `cases` enum and `is(_:)`

A `cases: CaseIterable` enum lets you list every case once and check membership without unpacking payloads.

```swift
Loading<Int, E>.cases.allCases   // [.idle, .loading, .loaded, .failed]

let state: Loading<Int, E> = .loading(previous: 5)
state.is(.loading)               // true
state.is(.loaded)                // false

Loading<Int, E>.loaded(0).is(.loaded)   // true
Loading<Int, E>.failed(.x, previous: nil).is(.failed)  // true
```

---

## Equatable / Hashable

`Loading` conforms to `Equatable` and `Hashable` conditionally, when both `Success` and `Failure` do. Note Swift does **not** synthesize `Equatable` for tuple payloads, so `Loading<(Int, String), E>` is not `Equatable` — use case-pattern matching there.

```swift
Loading<Int, E>.loaded(7) == .loaded(7)                       // true
Loading<Int, E>.loading(previous: 1) != .loading(previous: 2) // true

var hasher = Hasher()
Loading<Int, E>.failed(.x, previous: 5).hash(into: &hasher)
```

---

## Functor / Monad laws

All standard laws hold; the test suite covers identity, composition, left identity, right identity, and associativity for representative case combinations.
