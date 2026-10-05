# Dependency injection with Reader

`Reader<Environment, Output>` wraps a `@Sendable (Environment) -> Output`. It lets a computation say "I need these dependencies" in its type, compose with other computations that need the same ones, and get them only once, at the edge, when you call it. It lives in `DataStructure` (operators in `DataStructureOperators`).

## Contents

- When to use it, and when not
- Building and running
- Composing
- Smaller environments: local, contramapEnvironment
- Testing
- Reader with another effect (stacks)

## When to use it, and when not

Use `Reader` when the environment is a dependency that comes from outside the computation: an API client, a database, a clock, a logger, feature flags, configuration loaded at launch. Things you'd otherwise thread through every function signature, or reach for as a singleton.

Don't use it for ordinary inputs. `Reader<Int, X>` that adds a number, or `Reader<String, X>` that formats a string, is just a function with a confusing name; write the function. A useful test: would the caller naturally have this value in hand as a normal argument? Then it's a parameter, not an environment.

Also don't wrap everything in `Reader` just because one leaf needs a dependency. Keep the pure logic as plain functions and use `Reader` at the layer that actually touches the dependencies.

## Building and running

```swift
import FP

struct User: Sendable, Equatable { let id: String; let name: String }

struct Dependencies: Sendable {
    let fetchUser: @Sendable (String) -> User?
    let log: @Sendable (String) -> Void
    let isEnabled: @Sendable (String) -> Bool
}

// a computation that needs Dependencies
let loadUser: @Sendable (String) -> Reader<Dependencies, User?> = { id in
    Reader { deps in
        deps.log("loading \(id)")
        return deps.fetchUser(id)
    }
}

// the environment itself, or a piece of it
let wholeEnvironment: Reader<Dependencies, Dependencies> = .ask
let featureCheck: Reader<Dependencies, @Sendable (String) -> Bool> = .asks(get(\.isEnabled))

// running it: Reader is callable (callAsFunction), or use runReader
let live = Dependencies(fetchUser: { User(id: $0, name: "Ada") }, log: ignore, isEnabled: const(true))
let ada = loadUser("1")(live)
```

`get(\.isEnabled)` and not a bare `\.isEnabled`: Swift's key-path-as-function conversion isn't `@Sendable`, and `asks` wants a `@Sendable` closure.

## Composing

`map`, `flatMap`, `zip` and the operators work like on any monad, with the environment shared by every step:

```swift
let userName: @Sendable (String) -> Reader<Dependencies, String> = { id in
    loadUser(id).map { $0?.name ?? "unknown" }
}

let greeting: @Sendable (String) -> Reader<Dependencies, String> = { id in
    Reader<Dependencies, Bool>.asks { $0.isEnabled("greetings") } >>- { enabled in
        enabled ? userName(id).map { "Hello, \($0)" } : .pure("Hi")
    }
}

// independent readers, combined applicatively
let twoNames: Reader<Dependencies, (String, String)> = Reader.zip(userName("1"), userName("2"))

// Kleisli: functions returning Readers compose before any environment exists
let shout: @Sendable (String) -> Reader<Dependencies, String> = { name in .pure(name.uppercased()) }
let shoutedName = userName >=> shout
```

## Smaller environments: local, contramapEnvironment

Write each piece against the smallest environment it needs, then adapt it to the bigger one at composition time:

```swift
struct Clock: Sendable { let now: @Sendable () -> Double }
struct AppEnvironment: Sendable { let dependencies: Dependencies; let clock: Clock }

let timestamp: Reader<Clock, Double> = Reader { $0.now() }

// Reader<Clock, _> used where an AppEnvironment is available
let appTimestamp: Reader<AppEnvironment, Double> = timestamp.contramapEnvironment(get(\.clock))

// local: run with a modified environment of the same type
let quietLoad: Reader<Dependencies, User?> = loadUser("1").local { deps in
    Dependencies(fetchUser: deps.fetchUser, log: ignore, isEnabled: deps.isEnabled)
}
```

`contramapEnvironment` keeps every component honest about what it needs, which is the real benefit of `Reader` over a big shared container. `dimap` does both sides at once.

## Testing

The environment is the seam: build one with stubs, run, assert. No mocking framework, no globals.

```swift
import Testing

@Test func greetsByNameWhenEnabled() {
    let testDeps = Dependencies(fetchUser: { User(id: $0, name: "Test") }, log: ignore, isEnabled: const(true))
    #expect(greeting("1")(testDeps) == "Hello, Test")
}
```

## Reader with another effect (stacks)

When the output is itself an effect (`Reader<Env, User?>`, `Reader<Env, Result<A, E>>`), `map` and `>>-` on the bare `Reader` see the whole `User?`. Wrap it in its transformer stack with `.readerT` to work on the inner value, and leave with `.rawValue`:

```swift
enum LoadError: Error, Sendable { case missing }

let requireUser: @Sendable (String) -> Reader<Dependencies, Result<User, LoadError>> = { id in
    loadUser(id).map { $0.map(Result.success) ?? .failure(.missing) }
}

// ReaderTResult: map / flatMap reach through the Result and short-circuit on failure
let requiredName: @Sendable (String) -> Reader<Dependencies, Result<String, LoadError>> = { id in
    requireUser(id).readerT.map(get(\.name)).rawValue
}

let bothNames: Reader<Dependencies, Result<String, LoadError>> = (
    requireUser("1").readerT >>- { first in
        requireUser("2").readerT.map { "\(first.name) & \($0.name)" }
    }
).rawValue
```

`ReaderTOptional`, `ReaderTEither`, `ReaderTArray`, `ReaderTWriter`, `ReaderTStateful`, `ReaderTPublisher`, `ReaderTAsyncStream` and `ReaderTValidation` (applicative only) work the same way. See `transformer-stacks.md` for the model and the escape hatch `mapReaderT`.
