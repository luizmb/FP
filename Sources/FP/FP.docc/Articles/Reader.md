# Reader

`Reader<Environment, Output>` is a wrapper for a function `(Environment) -> Output`.

It solves the **dependency injection** problem: instead of passing a configuration or service object through every function call, you describe computations that *need* an environment and compose them freely. The environment is provided once, at the edge of your program.

```swift
import Reader

// A Reader is just a function from Environment to Output
let greeting = Reader<String, String> { name in "Hello, \(name)!" }
greeting("Alice")  // "Hello, Alice!"
```

---

## `<£>` and `<&>` — Map

Transform the output of a reader without changing what environment it needs. `<£>` puts the function on the left; `<&>` puts the reader on the left.

```swift
struct Config { let multiplier: Int }

let base = Reader<Config, Int> { $0.multiplier * 10 }

{ $0 + 1 } <£> base   // Reader that produces (multiplier * 10) + 1
base <&> { $0 + 1 }   // same

let result = ({ $0 + 1 } <£> base)(Config(multiplier: 3))  // 31

// Named function
base.mapReader { $0 + 1 }
base.fmap { $0 + 1 }
```

---

## `£>` and `<£` — Replace

Replace the output with a constant.

```swift
base £> "done"   // Reader that always produces "done", regardless of output
"done" <£ base   // same

let result = (base £> "done")(Config(multiplier: 3))  // "done"
```

---

## `<*>` — Apply

Combine two readers that share the same environment: one producing a function, one producing a value.

```swift
let addOffset = Reader<Config, (Int) -> Int> { env in { $0 + env.multiplier } }
let value     = Reader<Config, Int> { env in env.multiplier * 10 }

let result = (addOffset <*> value)(Config(multiplier: 3))  // 3 + (3 * 10) = 33

// Named function
Reader.apply(addOffset, value)(Config(multiplier: 3))  // 33
```

---

## `*>` and `<*` — Sequence

Run two readers against the same environment, keeping only one result.

```swift
let logStep = Reader<Config, String> { _ in "logged" }
let compute = Reader<Config, Int>    { $0.multiplier * 2 }

(logStep *> compute)(Config(multiplier: 5))  // 10  (log runs but result is discarded)
(compute <* logStep)(Config(multiplier: 5))  // 10  (compute result kept)

// Named functions
compute.seqRight(logStep)  // runs both, returns logStep's result
compute.seqLeft(logStep)   // runs both, returns compute's result
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain readers where the next reader depends on the output of the previous one. Both share the same environment. `>>-` puts the reader on the left; `-<<` puts the function on the left.

```swift
let multiplier = Reader<Config, Int> { $0.multiplier }
let scaled     = multiplier >>- { n in Reader<Config, Int> { env in n * env.multiplier } }

scaled(Config(multiplier: 3))  // 9  (3 * 3)

let scaleBy: (Int) -> Reader<Config, Int> = { n in Reader { env in n * env.multiplier } }
let scaled2 = scaleBy -<< multiplier   // same result

// Named function
multiplier.flatMap { n in Reader { env in n * env.multiplier } }
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Reader`.

```swift
let parse:    (String) -> Reader<Config, Int>    = { s in Reader { _ in Int(s) ?? 0 } }
let scale:    (Int)    -> Reader<Config, Int>    = { n in Reader { env in n * env.multiplier } }
let display:  (Int)    -> Reader<Config, String> = { n in Reader { _ in "Result: \(n)" } }

let pipeline = parse >=> scale >=> display
pipeline("6")(Config(multiplier: 7))  // "Result: 42"

// Named function
Reader.kleisli(parse, scale)("6")(Config(multiplier: 7))  // 42
```

---

## Environment operations

```swift
// ask — reader that returns the environment itself
Reader<Config, Config>.ask(Config(multiplier: 5))  // Config(multiplier: 5)

// asks — reader that projects a field from the environment
Reader.asks(\.multiplier)(Config(multiplier: 5))   // 5

// local — run a reader with a modified environment
let doubled = base.local { Config(multiplier: $0.multiplier * 2) }
doubled(Config(multiplier: 3))  // 60  (base would give 30, but env is doubled first)

// contramapEnvironment — adapt a reader to a larger environment
struct AppConfig { let config: Config }
let appBase = base.contramapEnvironment(\.config)
appBase(AppConfig(config: Config(multiplier: 3)))  // 30
```

---

## `pure` — constant reader

`pure` lifts a value into a `Reader` that ignores the environment and always returns the same value.

```swift
let always42 = Reader<Config, Int>.pure(42)
always42(Config(multiplier: 1))   // 42
always42(Config(multiplier: 99))  // 42

// Useful as a default or seed in applicative pipelines:
let seed = Reader<Config, Int>.pure(0)
let result = Reader.liftA2({ a, b in a + b })(base, seed)(Config(multiplier: 3))
// same as base(Config(multiplier: 3)) + 0
```

---

## ReaderT — Reader with inner effects

When your environment-dependent computation also has an inner effect (Optional, Result, Array, etc.), use the transformer variants. All operators work through both layers.

```swift
// Reader<Env, A?> — may not produce a value
let maybeUser = Reader<Config, Int?> { env in
    env.multiplier > 0 ? .some(env.multiplier * 10) : nil
}

// mapT maps inside the Optional without touching the Reader layer
let userName = maybeUser.mapT { "User #\($0)" }
userName(Config(multiplier: 3))   // Optional("User #30")
userName(Config(multiplier: -1))  // nil

// All operators work the same way
{ "User #\($0)" } <£> maybeUser   // Reader<Config, String?> — same result

// Reader<Env, Result<A, E>> — may fail with a typed error
// Reader<Env, [A]>           — may return multiple results
// Reader<Env, Either<L, R>>  — left/right choice
// Reader<Env, AsyncStream<A>>     — async sequence of values
// Reader<Env, AnyPublisher<A,E>> — reactive stream (Apple platforms)
```

---

## Comonad — extract and extend

`Reader` is a **Comonad** when its `Environment` is a `Monoid`. The Monoid identity acts as the "empty" environment, and `combine` merges environments.

```swift
struct Config: Monoid {
    static let identity = Config(multiplier: 1)
    static func combine(_ a: Config, _ b: Config) -> Config { Config(multiplier: a.multiplier * b.multiplier) }
    var multiplier: Int
}

let base = Reader<Config, Int> { $0.multiplier * 10 }

// extract — run the reader with the Monoid identity (the "empty" environment)
base.extract           // 10  (Config.identity.multiplier * 10)
extract(base)          // 10  (free function version)

// extend / coflatMap — map a function over the reader context as a whole
// Builds a new Reader that, for each environment e, creates a "shifted" reader
// and applies f to it.
let extended = base.extend { r in r.extract * 2 }
// Reader that produces extract * 2 for each shifted environment

base.coflatMap { r in r.extract + 1 }
// equivalent to extend

// duplicate — wrap the reader in another reader (dual of join)
base.duplicate
// Reader<Config, Reader<Config, Int>>

// Curried free functions for point-free composition
extend { r in r.extract * 2 }(base)
duplicate(base)
```

---

## Module

```swift
import Reader          // Reader type + named functions
import ReaderOperators // Operators (<£>, <*>, >>-, >=>…)
```

---

## For Haskell developers

| This library | Haskell equivalent |
|---|---|
| `Reader<Environment, Output>` | `mtl`'s `Reader r a` (`Control.Monad.Reader`), or `ReaderT r Identity a` in `transformers` |
| `<£>` / `<&>` (`fmap`) | `fmap` / `<$>` |
| `<*>` | `Applicative`'s `<*>` |
| `>>-` / `-<<` (`flatMap`) | `>>=` / `=<<` |
| `>=>` | `Control.Monad`'s `>=>` |
| `ask` | `MonadReader`'s `ask` |
| `asks` | `MonadReader`'s `asks` |
| `local` | `MonadReader`'s `local` |
| `contramapEnvironment` | `Control.Monad.Reader`'s `withReader` (adapts a reader to a different, related environment) |
| `pure` | `Applicative`'s `pure` / `return` |
| `ReaderT{Inner}` stacks | `mtl`'s `ReaderT r m a` |

The `Comonad` instance (available when `Environment: Monoid`) has a real Haskell counterpart — Kmett's `comonad` package defines a `Comonad` instance for `(->) e` requiring `e: Monoid`, for exactly the same reason: `extract` needs an "empty" environment to run against, and `duplicate`/`extend` need to `combine` environments. It's a legitimate instance, but a niche, rarely-discussed one — most Haskell material treats `Reader` purely as a `Monad` and doesn't reach for its comonadic side. This library exposing it explicitly is something Haskell *can* do but rarely emphasizes in practice.

External references:
- [`Control.Monad.Reader`](https://hackage.haskell.org/package/mtl/docs/Control-Monad-Reader.html) — the `mtl` module this type mirrors
- [`Control.Comonad`](https://hackage.haskell.org/package/comonad/docs/Control-Comonad.html) — Kmett's `comonad` package, source of the `(->) e` `Comonad` instance mentioned above
