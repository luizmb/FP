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

`Loading` is a `Functor` (`map`), a binary applicative via `zip`, a `Monad` (`flatMap`), and supports error recovery via `catch`. Operator forms — `<£>`, `<&>`, `£>`, `<£`, `>>-`, `-<<`, `>=>`, `<=<` — live in `DataStructureOperators`.

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
// .failed(error: .timeout, previous: [movie1, movie2])

// Or build a fresh Loading from a Result (no prior context).
let fresh = Loading<[Movie], NetworkError>.from(.success([]))
// .loaded([])
```

### `loadedOrPrevious` — the "don't blank the screen" accessor

Returns the loaded value, or the most recent `previous`. `nil` only for `.idle` and for
`.loading`/`.failed` states that never had a successful fetch to fall back on.

```swift
Loading<Int, MyError>.idle.loadedOrPrevious                                // nil
Loading<Int, MyError>.loading(previous: nil).loadedOrPrevious              // nil
Loading<Int, MyError>.loading(previous: 42).loadedOrPrevious               // 42
Loading<Int, MyError>.loaded(7).loadedOrPrevious                           // 7
Loading<Int, MyError>.failed(error: .network, previous: 3).loadedOrPrevious       // 3
```

This is the property to reach for in a view: it collapses three of the four cases
(`.loaded`, `.loading(previous:)`, `.failed(_, previous:)`) down to "the best value I
currently have to show," so a screen never has to blank itself out just because a refresh
is in flight or the last attempt failed. Compare the two approaches to rendering the same
list:

```swift
// Without loadedOrPrevious — switches to an empty/spinner state on every refresh,
// even when there's perfectly good data still on screen from the last successful fetch.
switch state {
case .idle, .loading:
    ProgressView()
case let .loaded(movies):
    MovieList(movies)
case .failed:
    ErrorView()
}

// With loadedOrPrevious — refreshing (or a failed refresh) keeps showing the last
// good list; only genuinely empty states (.idle, or a failure/loading with no prior
// data at all) fall through to a full-screen placeholder.
if let movies = state.loadedOrPrevious {
    MovieList(movies)          // stays on screen through .loading and .failed alike
} else {
    switch state {
    case .idle: EmptyStateView()
    case .loading: ProgressView()
    case .failed: ErrorView()
    case .loaded: EmptyView()  // unreachable: .loaded always has a loadedOrPrevious
    }
}
```

The second version is the pattern this type exists for: pull-to-refresh and background
poll/retry loops feel broken when the whole screen flashes to a spinner or an error page
every time they run — `loadedOrPrevious` is what lets a view keep the last-known-good
content on screen and layer a lighter-weight signal (a small inline spinner, a toast, a
banner) on top instead, using `state.is(.loading)` / `state.failed != nil` alongside it to
decide whether to show that lighter-weight signal at all.

---

## `<£>` and `<&>` — Map

Transform the `Success` channel. `previous` values in `.loading` and `.failed` are mapped too, so stale data stays consistent. `.idle` and the `Failure` channel pass through unchanged.

```swift
{ $0 * 2 } <£> Loading<Int, E>.loaded(5)                  // .loaded(10)
{ $0 * 2 } <£> Loading<Int, E>.loading(previous: 3)       // .loading(previous: 6)
{ $0 * 2 } <£> Loading<Int, E>.failed(error: .x, previous: 4)    // .failed(error: .x, previous: 8)
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
Loading<Int, E>.failed(error: .x, previous: 7) £> "done"         // .failed(error: .x, previous: "done")
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

L<(Int, String)>.zip(.failed(error: .network, previous: 1), .loaded("a"))
// .failed(error: .network, previous: Optional((1, "a")))
```

> `Loading` doesn't expose `<*>` / `pure` because there is no canonical way to wrap a single value as `.idle` / `.loading` / `.failed`. Use `zip` when you need applicative-style combination.

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
    .failed(error: .timeout, previous: 7)
    .catch { _ in .loaded(0) }
// .loaded(0)

// Map one error into another
Loading<Int, NetworkError>
    .failed(error: .timeout, previous: nil)
    .catch { _ in .failed(error: .cancelled, previous: nil) }
// .failed(error: .cancelled, previous: nil)

// Non-failed cases pass through
Loading<Int, NetworkError>.idle.catch { _ in .loaded(0) }              // .idle
Loading<Int, NetworkError>.loading(previous: 7).catch { _ in .loaded(0) }
// .loading(previous: 7)
```

---

## Prisms, `cases`, and `is(_:)`

`Loading` ships hand-written equivalents of what FP's `@Prisms` macro generates. Because `Loading` is generic, Swift forbids `static let` in its scope, so `prism` is a computed `static var` returning a fresh `Prisms()` per access — matching what the macro emits for any generic host.

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

### Per-case properties

Each case also has a plain property on the instance — no `@dynamicMemberLookup` involved, just one named property per case, each delegating to the `Prism` above. `if let` reads directly against a `Loading` value without going through `.prism.loaded.preview(...)`. Note that `.loading` is a double optional because its own focus type is already `Success?`.

```swift
let state: Loading<Int, E> = .loaded(42)
state.loaded                    // Optional(42)
state.idle                       // nil
state.loading                    // nil
state.failed                     // nil

if let value = state.loaded {
    render(value)
}

let inFlight: Loading<Int, E> = .loading(previous: 7)
inFlight.loading                 // Optional(Optional(7))  — double optional
inFlight.loading ?? nil          // Optional(7)
```

### `Cases` enum, `is(_:)`, and `HasCases`

A nested `Cases: CoreFP.CaseMatchable` enum lets you list every case once and check membership without unpacking payloads. `Loading` conforms to `CoreFP.HasCases`, so `is(_:)` is available both as a direct method and via the polymorphic protocol extension.

```swift
Loading<Int, E>.Cases.allCases   // [.idle, .loading, .loaded, .failed]

let state: Loading<Int, E> = .loading(previous: 5)
state.is(.loading)               // true
state.is(.loaded)                // false

Loading<Int, E>.loaded(0).is(.loaded)   // true
Loading<Int, E>.failed(error: .x, previous: nil).is(.failed)  // true

// Polymorphic use via HasCases:
func currentIsFirstCase<T: HasCases>(_ v: T) -> Bool {
    v.is(T.Cases.allCases.first!)
}
currentIsFirstCase(state)        // true if state matches `cases.allCases[0]` (i.e. .idle)
```

---

## Equatable / Hashable

`Loading` conforms to `Equatable` and `Hashable` conditionally, when both `Success` and `Failure` do. Note Swift does **not** synthesize `Equatable` for tuple payloads, so `Loading<(Int, String), E>` is not `Equatable` — use case-pattern matching there.

```swift
Loading<Int, E>.loaded(7) == .loaded(7)                       // true
Loading<Int, E>.loading(previous: 1) != .loading(previous: 2) // true

var hasher = Hasher()
Loading<Int, E>.failed(error: .x, previous: 5).hash(into: &hasher)
```

---

## Functor / Monad laws

All standard laws hold; the test suite covers identity, composition, left identity, right identity, and associativity for representative case combinations.

---

## For Haskell developers

`Loading<Success, Failure>` has **no direct Haskell equivalent** — it isn't modeling a general-purpose algebraic structure, it's modeling a specific, opinionated shape: the four states a piece of async UI state moves through in a Swift app (`.idle` → `.loading` → `.loaded`/`.failed`), plus the "keep the stale value visible while refreshing" `previous` payload. Haskell code that needs this typically defines the ADT ad hoc per-project rather than reaching for a shared library type, because the concern is UI/application-state modeling, not pure computation.

| This library | Closest parallel |
|---|---|
| `Loading<Success, Failure>` | a bespoke 4-case ADT (no canonical Haskell name); closest **named**, citable prior art is `RemoteData` from the Elm/PureScript ecosystem |
| `.idle` / `.loading` / `.loaded` / `.failed` | `RemoteData`'s `NotAsked` / `Loading` / `Success` / `Failure` |
| `map` / `<£>` | `fmap` (mapped over the `Success` channel, same as `RemoteData`'s `Functor`) |
| `flatMap` / `>>-` | `>>=` (only `.loaded`/`Success` invokes the continuation) |
| `catch` | error-recovery combinator, analogous to `RemoteData`'s `mapError`/withDefault-style helpers |

The reason to reach past Haskell entirely here: `RemoteData` (originally from Elm, ported to PureScript as `purescript-remotedata`) is the exact same idea — a `NotAsked | Loading | Failure e | Success a` sum type purpose-built for representing a remote/async resource's lifecycle in a UI — and it is real, well-known, and directly citable, whereas forcing a `base`-package Haskell type onto this shape would be misleading; nothing in `base` or common Haskell web frameworks models this pattern as a shared, named type.

**References:**
- [`purescript-remotedata`](https://github.com/krisajenkins/purescript-remotedata) — the citable prior art this type's shape most closely mirrors
- [Kris Jenkins — "How Elm Slays a UI Antipattern"](https://blog.jenkster.com/2016/06/how-elm-slays-a-ui-antipattern/) (the original `RemoteData` write-up)
