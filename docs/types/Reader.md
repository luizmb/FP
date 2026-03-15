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

## `<£>` — Map

Transform the output of a reader without changing what environment it needs.

```swift
struct Config { let multiplier: Int }

let base = Reader<Config, Int> { $0.multiplier * 10 }

{ $0 + 1 } <£> base   // Reader that produces (multiplier * 10) + 1

let result = ({ $0 + 1 } <£> base)(Config(multiplier: 3))  // 31

// Named function
base.mapReader { $0 + 1 }  // same as above
base.fmap { $0 + 1 }       // same as above
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

## `<&>` — Flipped map

Same as `<£>` with the reader on the left.

```swift
base <&> { $0 + 1 }   // same as { $0 + 1 } <£> base
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

## `>>-` — Bind (flatMap)

Chain readers where the next reader depends on the output of the previous one. Both share the same environment.

```swift
let multiplier = Reader<Config, Int> { $0.multiplier }
let scaled     = multiplier >>- { n in Reader<Config, Int> { env in n * env.multiplier } }

scaled(Config(multiplier: 3))  // 9  (3 * 3)

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

## Module

```swift
import Reader          // Reader type + named functions
import ReaderOperators // Operators (<£>, <*>, >>-, >=>…)
```
