# ``Loading``

`Loading<Success, Failure>` is a four-state lifecycle enum for async operations: `.idle`, `.loading(previous:)`, `.loaded(Success)`, and `.failed(Failure, previous:)`. The `previous` payload on `.loading` and `.failed` carries the last successful value so UIs can keep displaying stale data while a refresh is in flight or after an error.

```swift-sketch
import DataStructure

public enum Loading<Success: Sendable, Failure: Sendable>: Sendable {
    case idle
    case loading(previous: Success?)
    case loaded(Success)
    case failed(Failure, previous: Success?)
}
```

`Loading` is a Functor (`map`), an Applicative (`pure`, `apply`, `liftA2`, `zip`, all derived from bind), a Monad (`flatMap`), with error recovery via `catch`, plus `pessimisticCombine` for the UI "any failure wins" rule. Operators: `<£>`, `<&>`, `£>`, `<£`, `<*>`, `*>`, `<*`, `>>-`, `-<<`, `>=>`, `<=<` (they live in `DataStructureOperators`).

The examples in this article share a few context types:

```swift
import DataStructure
import DataStructureOperators

enum NetworkError: Error, Sendable { case timeout, network }
enum AuthError: Error, Sendable { case denied }
enum E: Error, Sendable { case x }
struct Movie: Sendable, Equatable { let title: String }
struct Session: Sendable { let token: Int }
struct Profile: Sendable { let name: String }

let movie1 = Movie(title: "Alien")
let movie2 = Movie(title: "Heat")
```

---

## Construction & state transitions

The state machine is driven by `Result`. The three transition helpers preserve `loadedOrPrevious` so stale data is never thrown away accidentally.

```swift
var state: Loading<[Movie], NetworkError> = .idle

// Kick off a fetch, carrying `loadedOrPrevious` into `.loading`.
state = state.startLoading()
// .loading(previous: nil)

// Resolve to a Result: `.loaded` on success, `.failed(_, previous:)` on failure.
state = state.applying(.success([movie1, movie2]))
// .loaded([movie1, movie2])

state = state.startLoading()
// .loading(previous: [movie1, movie2]), stale data preserved during refresh

state = state.applying(.failure(.timeout))
// .failed(error: .timeout, previous: [movie1, movie2])

// Or build a fresh Loading from a Result (no prior context).
let fresh = Loading<[Movie], NetworkError>(.success([]))
// .loaded([])
```

### `loadedOrPrevious` — the "don't blank the screen" accessor

Returns the loaded value, or the most recent `previous`. `nil` only for `.idle` and for
`.loading`/`.failed` states that never had a successful fetch to fall back on.

```swift
let kept1 = Loading<Int, NetworkError>.idle.loadedOrPrevious                                      // nil
let kept2 = Loading<Int, NetworkError>.loading(previous: nil).loadedOrPrevious                    // nil
let kept3 = Loading<Int, NetworkError>.loading(previous: 42).loadedOrPrevious                     // 42
let kept4 = Loading<Int, NetworkError>.loaded(7).loadedOrPrevious                                 // 7
let kept5 = Loading<Int, NetworkError>.failed(error: .network, previous: 3).loadedOrPrevious      // 3
```

This is the property to reach for in a view: it collapses three of the four cases
(`.loaded`, `.loading(previous:)`, `.failed(_, previous:)`) down to "the best value I
currently have to show," so a screen never has to blank itself out just because a refresh
is in flight or the last attempt failed. Compare the two approaches to rendering the same
list:

```swift-sketch
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
every time they run, and `loadedOrPrevious` is what lets a view keep the last-known-good
content on screen and layer a lighter-weight signal (a small inline spinner, a toast, a
banner) on top instead, using `state.is(.loading)` / `state.failed != nil` alongside it to
decide whether to show that lighter-weight signal at all.

---

## `<£>` and `<&>` — Map

Transform the `Success` channel. `previous` values in `.loading` and `.failed` are mapped too, so stale data stays consistent. `.idle` and the `Failure` channel pass through unchanged.

```swift
let map1 = { $0 * 2 } <£> Loading<Int, E>.loaded(5)                       // .loaded(10)
let map2 = { $0 * 2 } <£> Loading<Int, E>.loading(previous: 3)            // .loading(previous: 6)
let map3 = { $0 * 2 } <£> Loading<Int, E>.failed(error: .x, previous: 4)  // .failed(error: .x, previous: 8)
let map4 = { $0 * 2 } <£> Loading<Int, E>.idle                            // .idle

let map5 = Loading<Int, E>.loaded(5) <&> { $0 * 2 }                       // .loaded(10)

// Named functions
let map6 = Loading<Int, E>.fmap { $0 * 2 }(.loaded(5))   // .loaded(10)
let map7 = Loading<Int, E>.loaded(5).map { $0 * 2 }      // .loaded(10)
```

---

## `£>` and `<£` — Replace

Replace the loaded value with a constant.

```swift
let replace1 = Loading<Int, E>.loaded(42) £> "done"                       // .loaded("done")
let replace2 = Loading<Int, E>.failed(error: .x, previous: 7) £> "done"  // .failed(error: .x, previous: "done")
let replace3 = "done" <£ Loading<Int, E>.loaded(42)                      // .loaded("done")
```

---

## `zip` and the applicative

`pure` is `.loaded`, and `apply` / `<*>`, `liftA2`, `*>`, `<*` are `ap` derived from `flatMap` (`<*> == ap`), so `zip(a, b) == a.flatMap { l in b.map { (l, $0) } }`. It is left-biased like PureScript's `RemoteData`: the right side only matters when the left is `.loaded`. So `zip(.idle, .failed(e))` is `.idle` and `zip(.loading(previous: nil), .failed(e))` is `.loading(previous: nil)` (`pessimisticCombine` gives `.failed` for both), and `zip(.loaded(1), x)` is `x.map { (1, $0) }`.

```swift
typealias L<A: Sendable> = Loading<A, NetworkError>

let zip1 = L<(Int, String)>.zip(.loaded(1), .loaded("a"))
// .loaded((1, "a"))

let zip2 = L<(Int, String)>.zip(.idle, .loaded("a"))
// .idle

let zip3 = L<(Int, String)>.zip(.loading(previous: 1), .loaded("a"))
// .loading(previous: nil), the left side decides and the pair has no previous

let zip4 = L<(Int, String)>.zip(.loaded(1), .failed(error: .network, previous: "a"))
// .failed(error: .network, previous: Optional("a")) mapped through the pair, left is loaded so the right decides

let zip5 = L<(Int, String)>.zip(.idle, .failed(error: .network, previous: "a"))
// .idle, the failure on the right is never looked at
```

## `pessimisticCombine` — UI rule (not the applicative)

When a screen waits on two requests and should show a failure as soon as either one failed, use `pessimisticCombine(_:_:)` (there are also 3-ary and 4-ary versions). Precedence, first match wins:

1. Either side `.failed` → `.failed` (first error, pair of `loadedOrPrevious` when both have one).
2. Either side `.idle` → `.idle`.
3. Either side `.loading` → `.loading` (pair of `loadedOrPrevious` when both have one).
4. Both `.loaded` → `.loaded(pair)`.

```swift
let combine1 = L<(Int, String)>.pessimisticCombine(.loaded(1), .loaded("a"))
// .loaded((1, "a"))

let combine2 = L<(Int, String)>.pessimisticCombine(.idle, .loaded("a"))
// .idle

let combine3 = L<(Int, String)>.pessimisticCombine(.loading(previous: 1), .loaded("a"))
// .loading(previous: Optional((1, "a")))

let combine4 = L<(Int, String)>.pessimisticCombine(.failed(error: .network, previous: 1), .loaded("a"))
// .failed(error: .network, previous: Optional((1, "a")))

let combine5 = L<(Int, String)>.pessimisticCombine(.idle, .failed(error: .network, previous: nil))
// .failed(error: .network, previous: nil), where zip would have given .idle
```

---

## `>>-`, `-<<`, `>=>`, `<=<` — Bind & Kleisli

Chain operations that each return a `Loading`. `.loaded` is the only state that actually invokes the continuation; the others pass through, with `previous` mapped through the function so stale-data invariants survive the chain.

```swift
@Sendable func authorize(_ id: Int) -> Loading<Session, AuthError> { .loaded(Session(token: id)) }
@Sendable func fetchProfile(_ session: Session) -> Loading<Profile, AuthError> { .loaded(Profile(name: "user\(session.token)")) }

let bound = Loading<Int, AuthError>.loaded(42)
    >>- authorize
    >>- fetchProfile

// Function on the left
let bound2 = fetchProfile -<< (authorize -<< Loading<Int, AuthError>.loaded(42))

// Kleisli composition (build the pipeline once, run later)
let pipeline = authorize >=> fetchProfile
let piped = pipeline(42)                       // Loading<Profile, AuthError>

let pipelineBack = fetchProfile <=< authorize
let pipedBack = pipelineBack(42)               // Loading<Profile, AuthError>

// Named functions
let flatMapped = Loading<Int, AuthError>.loaded(42).flatMap(authorize)
let kleisli = Loading<Session, AuthError>.kleisli(authorize, fetchProfile)(42)
```

---

## `Failure` is any `Sendable` type

`Loading` doesn't require `Failure: Error`. In the UI the failure is usually a `String` or a struct with a title and subtitle, and a non-`Error` failure keeps `Loading` easy to make `Equatable`. Only the `Result` bridges (`applying(_:)` and `init(_:)`) need `Failure: Error`. Map a technical error into a view message the same way you map a DTO into a view state:

```swift
struct Banner: Equatable, Sendable { let title: String; let subtitle: String }

let request: Loading<Profile, NetworkError> = .failed(error: .timeout, previous: nil)
let screen: Loading<Profile, Banner> = request
    .mapError { error in Banner(title: "Couldn't load your profile", subtitle: "\(error)") }
```

`bimap(_:_:)` maps both channels at once.

## `catch` — Recover from failure

`.failed` can be transformed into any other `Loading`, possibly with another failure type (Haskell's `catchE`). The handler also receives the stale `previous` value so it can keep showing it. The other cases pass through.

```swift
let recovered: Loading<Int, NetworkError> = Loading<Int, NetworkError>
    .failed(error: .timeout, previous: 7)
    .catch { _, _ in .loaded(0) }
// .loaded(0)

// Retry, keeping the stale data on screen
let retried = Loading<Int, NetworkError>
    .failed(error: .timeout, previous: 7)
    .catch { _, previous in Loading<Int, NetworkError>.loading(previous: previous) }
// .loading(previous: 7)

// Non-failed cases pass through
let untouched = Loading<Int, NetworkError>.idle.catch { _, _ in Loading<Int, NetworkError>.loaded(0) }   // .idle
```

---

## Prisms, `cases`, and `is(_:)`

`Loading` ships hand-written equivalents of what FP's `@Prisms` macro generates. Because `Loading` is generic, Swift forbids `static let` in its scope, so `prism` is a computed `static var` returning a fresh `Prisms()` per access, matching what the macro emits for any generic host.

### `Loading.prism.<case>` — `CoreFP.Prism`

```swift
let idlePrism: Prism<Loading<Int, E>, Void> = Loading<Int, E>.prism.idle
let loadingPrism: Prism<Loading<Int, E>, Int?> = Loading<Int, E>.prism.loading
let loadedPrism: Prism<Loading<Int, E>, Int> = Loading<Int, E>.prism.loaded
let failedPrism: Prism<Loading<Int, E>, (E, Int?)> = Loading<Int, E>.prism.failed

let previewed1 = Loading<Int, E>.prism.loaded.preview(.loaded(7))                    // 7
let previewed2 = Loading<Int, E>.prism.loaded.preview(.idle)                         // nil
let reviewed = Loading<Int, E>.prism.loaded.review(42)                               // .loaded(42)
let setted = Loading<Int, E>.prism.loaded.set(.loaded(1), 99)                        // .loaded(99)
let overed = Loading<Int, E>.prism.loaded.over({ $0 * 2 })(.loaded(5))               // .loaded(10)
```

### Per-case properties

Each case also has a plain property on the instance — no `@dynamicMemberLookup` involved, just one named property per case, each delegating to the `Prism` above. `if let` reads directly against a `Loading` value without going through `.prism.loaded.preview(...)`. Note that `.loading` is a double optional because its own focus type is already `Success?`.

```swift
let current: Loading<Int, E> = .loaded(42)
let p1 = current.loaded                    // Optional(42)
let p2 = current.idle                      // nil
let p3 = current.loading                   // nil
let p4 = current.failed                    // nil

if let value = current.loaded {
    print(value)
}

let inFlight: Loading<Int, E> = .loading(previous: 7)
let double1 = inFlight.loading             // Optional(Optional(7)), double optional
let double2 = inFlight.loading ?? nil      // Optional(7)
```

### `Cases` enum, `is(_:)`, and `HasCases`

A nested `Cases: CoreFP.CaseMatchable` enum lets you list every case once and check membership without unpacking payloads. `Loading` conforms to `CoreFP.HasCases`, so `is(_:)` is available both as a direct method and via the polymorphic protocol extension.

```swift
let allCases = Loading<Int, E>.Cases.allCases   // [.idle, .loading, .loaded, .failed]

let pending: Loading<Int, E> = .loading(previous: 5)
let is1 = pending.is(.loading)               // true
let is2 = pending.is(.loaded)                // false

let is3 = Loading<Int, E>.loaded(0).is(.loaded)   // true
let is4 = Loading<Int, E>.failed(error: .x, previous: nil).is(.failed)  // true

// Polymorphic use via HasCases:
func currentIsFirstCase<T: HasCases>(_ v: T) -> Bool {
    T.Cases.allCases.first.map(v.is) ?? false
}
let isFirst = currentIsFirstCase(pending)    // true if pending matches `Cases.allCases[0]` (i.e. .idle)
```

---

## Equatable / Hashable

`Loading` conforms to `Equatable` and `Hashable` conditionally, when both `Success` and `Failure` do. Note Swift does **not** synthesize `Equatable` for tuple payloads, so `Loading<(Int, String), E>` is not `Equatable` — use case-pattern matching there.

```swift
let eq1 = Loading<Int, E>.loaded(7) == .loaded(7)                       // true
let eq2 = Loading<Int, E>.loading(previous: 1) != .loading(previous: 2) // true

var hasher = Hasher()
Loading<Int, E>.failed(error: .x, previous: 5).hash(into: &hasher)
```

---

## Functor / Monad laws

All standard laws hold; the test suite covers identity, composition, left identity, right identity, and associativity for representative case combinations. The Applicative laws hold as well, and `<*> == ap` is tested.

---

## For Haskell developers

`Loading<Success, Failure>` has **no direct Haskell equivalent** — it isn't modeling a general-purpose algebraic structure, it's modeling a specific, opinionated shape: the four states a piece of async UI state moves through in a Swift app (`.idle` → `.loading` → `.loaded`/`.failed`), plus the "keep the stale value visible while refreshing" `previous` payload. Haskell code that needs this typically defines the ADT ad hoc per-project rather than reaching for a shared library type, because the concern is UI/application-state modeling, not pure computation.

| This library | Closest parallel |
|---|---|
| `Loading<Success, Failure>` | a bespoke 4-case ADT (no canonical Haskell name); closest **named**, citable prior art is `RemoteData` from the Elm/PureScript ecosystem |
| `.idle` / `.loading` / `.loaded` / `.failed` | `RemoteData`'s `NotAsked` / `Loading` / `Success` / `Failure` |
| `map` / `<£>` | `fmap` (mapped over the `Success` channel, same as `RemoteData`'s `Functor`) |
| `flatMap` / `>>-` | `>>=` (only `.loaded`/`Success` invokes the continuation) |
| `catch` | Haskell's `catchE` (the handler receives `(Failure, Success?)` and may change the failure type) |

The reason to reach past Haskell entirely here: `RemoteData` (originally from Elm, ported to PureScript as `purescript-remotedata`) is the exact same idea — a `NotAsked | Loading | Failure e | Success a` sum type purpose-built for representing a remote/async resource's lifecycle in a UI — and it is real, well-known, and directly citable, whereas forcing a `base`-package Haskell type onto this shape would be misleading; nothing in `base` or common Haskell web frameworks models this pattern as a shared, named type.

**References:**
- [`purescript-remotedata`](https://github.com/krisajenkins/purescript-remotedata) — the citable prior art this type's shape most closely mirrors
- [Kris Jenkins — "How Elm Slays a UI Antipattern"](https://blog.jenkster.com/2016/06/how-elm-slays-a-ui-antipattern/) (the original `RemoteData` write-up)
