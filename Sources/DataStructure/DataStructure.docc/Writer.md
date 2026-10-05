# ``Writer``

`Writer<W: Monoid, A>` is a pair of a value `A` and a log `W`.

It solves the **accumulating output** problem: instead of threading a log or accumulator through every function manually, you describe computations that *produce* a value and *append* to a log simultaneously. The log entries are collected automatically as computations are chained. The log type `W` must be a `Monoid` so the library knows how to combine entries and what the empty log looks like.

```swift
import DataStructure

// A computation that produces 42 and logs a message
let answer = Writer(42, ["computed the answer"])

answer.value        // 42
answer.log          // ["computed the answer"]
answer.runWriter()  // (42, ["computed the answer"])
answer.evalWriter() // 42
answer.execWriter() // ["computed the answer"]
```

---

## `<£>` and `<&>` — Map

Transform the value without touching the log.

```swift
let timesTwo: @Sendable (Int) -> Int = { $0 * 2 }

timesTwo <£> Writer(21, ["step 1"])   // Writer(42, ["step 1"])
Writer(21, ["step 1"]) <&> timesTwo   // Writer(42, ["step 1"])

// Named functions
Writer(21, ["step 1"]).map(timesTwo)
Writer(21, ["step 1"]).mapWriter(timesTwo)
```

---

## `£>` and `<£` — Replace

Replace the value with a constant. The log is preserved.

```swift
Writer(42, ["step 1"]) £> "done"  // Writer("done", ["step 1"])
"done" <£ Writer(42, ["step 1"])  // Writer("done", ["step 1"])
```

---

## `<*>` — Apply

Combine two writers: one holding a function, one holding a value. Logs are combined using `Monoid.combine`.

```swift
Writer(timesTwo, ["fn loaded"]) <*> Writer(21, ["value ready"])
// Writer(42, ["fn loaded", "value ready"])

// Named functions
Writer<[String], Int>.apply(Writer(timesTwo, ["fn"]), Writer(21, ["val"]))
// Writer(42, ["fn", "val"])

Writer<[String], (Int, Int)>.zip(Writer(1, ["a"]), Writer(2, ["b"]))
// Writer((1, 2), ["a", "b"])

Writer<[String], Int>.liftA2 { (a: Int, b: Int) in a + b }(Writer(10, ["x"]), Writer(32, ["y"]))
// Writer(42, ["x", "y"])
```

---

## `*>` and `<*` — Sequence

Run two writers in sequence (logs combined), keeping only one value.

```swift
Writer(1, ["first"]) *> Writer(2, ["second"])  // Writer(2, ["first", "second"])
Writer(1, ["first"]) <* Writer(2, ["second"])  // Writer(1, ["first", "second"])

// Named functions
Writer(1, ["first"]).seqRight(Writer(2, ["second"]))
Writer(1, ["first"]).seqLeft(Writer(2, ["second"]))
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain writers where the next computation depends on the current value. All logs are accumulated.

```swift
let multiplied = Writer(6, ["start"])
    >>- { n in Writer(n * 7, ["multiplied by 7"]) }
// Writer(42, ["start", "multiplied by 7"])

let chained = Writer(2, ["a"])
    >>- { n in Writer(n + 10, ["added 10"]) }
    >>- { n in Writer(n * 2, ["doubled"]) }
// Writer(24, ["a", "added 10", "doubled"])

// Named functions
Writer(6, ["start"]).flatMap { n in Writer(n * 7, ["x7"]) }
Writer<[String], Int>.bind { n in Writer(n * 2, ["x2"]) }(Writer(21, ["init"]))
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Writer`.

```swift
let parse: @Sendable (String) -> Writer<[String], Int> = { s in Writer(Int(s) ?? 0, ["parsed"]) }
let validate: @Sendable (Int) -> Writer<[String], Int> = { n in Writer(max(0, n), ["validated"]) }
let format: @Sendable (Int) -> Writer<[String], String> = { n in Writer("Result: \(n)", ["formatted"]) }

let pipeline = parse >=> validate >=> format
pipeline("42").runWriter()  // ("Result: 42", ["parsed", "validated", "formatted"])

// Named function
Writer<[String], Int>.kleisli(parse, validate)("42")
```

---

## Writer primitives

```swift
// pure — wrap a value with an empty log
Writer<[String], Int>.pure(42)   // Writer(42, [])

// tell — produce Void and append to the log
Writer<[String], Void>.tell(["event happened"])   // Writer((), ["event happened"])

// Using tell in a chain
let program: Writer<[String], Int> =
    Writer<[String], Void>.tell(["start"]) *>
    (Writer(42, ["computed"]) >>- { n in
        Writer<[String], Void>.tell(["result: \(n)"]) *> Writer<[String], Int>.pure(n)
    })
program.runWriter()   // (42, ["start", "computed", "result: 42"])

// listen — expose the log as part of the value
Writer(42, ["a", "b"]).listen()   // Writer((42, ["a", "b"]), ["a", "b"])

// censor — transform the log without affecting the value
Writer(42, ["verbose message"]).censor { $0.map { $0.uppercased() } }
// Writer(42, ["VERBOSE MESSAGE"])
```

---

## Comonad — extract and extend

`Writer` is a **Comonad**: you can extract the current value and extend computations over the whole writer context.

```swift
// extract — pull out the value (dual of pure)
Writer(42, ["log"]).extract   // 42

// coflatMap / extend — map a function over the writer context as a whole
Writer(42, ["log"]).coflatMap { w in w.value * 2 + w.log.count }
// Writer(85, ["log"])   — value is (42 * 2 + 1), log preserved

Writer(10, ["a", "b"]).extend { w in w.execWriter().joined(separator: ",") }
// Writer("a,b", ["a", "b"])

// duplicate — wrap the writer in another writer (dual of join)
Writer(42, ["log"]).duplicate   // Writer(Writer(42, ["log"]), ["log"])

// Free functions
extract(Writer(42, ["log"]))            // 42
duplicate(Writer(42, ["log"]))          // Writer(Writer(42, ["log"]), ["log"])
extend { (w: Writer<[String], Int>) in w.value * 2 }(Writer(21, ["x"]))  // Writer(42, ["x"])

// Operators
let valueTimesTwo: @Sendable (Writer<[String], Int>) -> Int = { $0.value * 2 }
Writer(21, ["x"]) ->> valueTimesTwo   // Writer(42, ["x"])
valueTimesTwo <<- Writer(21, ["x"])   // Writer(42, ["x"])
```

---

## Traversable

`Writer` is Traversable when its value is a container. These operations "flip" the nesting.

```swift
// sequence: Writer<W, [A]> → [Writer<W, A>]
Writer(["a", "b", "c"], ["log"]).sequence()
// [Writer("a", ["log"]), Writer("b", ["log"]), Writer("c", ["log"])]

Writer<[String], Int>(1, []).traverse { [$0, $0 * 10] }
// [Writer(1, []), Writer(10, [])]

// sequence: Writer<W, A?> → Writer<W, A>?
Writer<[String], Int?>(42, ["log"]).sequence()    // Optional(Writer(42, ["log"]))
Writer<[String], Int?>(nil, ["log"]).sequence()   // nil

// sequence: Writer<W, Result<A, E>> → Result<Writer<W, A>, E>
enum LogError: Error, Sendable { case bad }

Writer<[String], Result<Int, LogError>>(.success(42), ["log"]).sequence()
// .success(Writer(42, ["log"]))

Writer<[String], Result<Int, LogError>>(.failure(.bad), ["log"]).sequence()
// .failure(.bad)

// Free function variants
sequence(Writer<[String], [Int]>([1, 2], ["log"]))   // [Writer(1, ["log"]), Writer(2, ["log"])]
traverse { (n: Int) in [n, n * 2] }(Writer<[String], Int>(5, ["log"]))  // [Writer(5, ["log"]), Writer(10, ["log"])]
```

---

## Monad Transformers

Writer participates in transformer stacks either as the **outer** layer (`WriterT{Inner}`) or as the **inner** layer (`{Outer}TWriter`, Haskell's `WriterT`). Each stack is its own struct around the nested value: lift in with the property on the outer type (`writer.writerT`, `optional.optionalT`, `array.arrayT`, …) or the stack's `init(_:)`, use `map` / `apply` / `flatMap` / the operators, and leave with `.rawValue`.

### `WriterTOptional` (wraps `Writer<W, A?>`, outer = Writer, inner = Optional)

Log accumulates regardless of whether a value is present.

```swift
let found: Writer<[String], Int?> = Writer(.some(5), ["found"])
found.writerT.map { $0 * 2 }.rawValue   // Writer(Optional(10), ["found"])

let empty: Writer<[String], Int?> = Writer(.none, ["not found"])
empty.writerT.map { $0 * 2 }.rawValue  // Writer(nil, ["not found"])
```

### `WriterTEither` (wraps `Writer<W, Either<L, A>>`, outer = Writer, inner = Either)

```swift
let okEither = WriterTEither<[String], String, Int>(Writer(.right(5), ["ok"]))
okEither.map { $0 * 2 }.rawValue   // Writer(.right(10), ["ok"])

let fail = WriterTEither<[String], String, Int>(Writer(.left("err"), ["failed"]))
fail.map { $0 * 2 }.rawValue  // Writer(.left("err"), ["failed"])
```

### `WriterTResult` (wraps `Writer<W, Result<A, E>>`, outer = Writer, inner = Result)

```swift
let okResult: Writer<[String], Result<Int, LogError>> = Writer(.success(5), ["ok"])
okResult.writerT.map { $0 * 2 }.rawValue   // Writer(.success(10), ["ok"])
```

### `WriterTStateful` (wraps `Writer<W, Stateful<S, A>>`, outer = Writer, inner = Stateful)

Produces a stateful computation alongside a log entry. Useful when you want to record that a state transition happened. Functor and Applicative only (no lawful monad with the log outside the effect).

```swift
let willIncrement: Writer<[String], Stateful<Int, Int>> =
    Writer(Stateful { s in
        s += 1
        return s
    }, ["will increment"])
willIncrement.writerT.map { $0 * 2 }  // WriterTStateful<[String], Int, Int>, doubles the result
```

### `WriterTReader` (wraps `Writer<W, Reader<Env, A>>`, outer = Writer, inner = Reader)

```swift
struct Config: Sendable { let multiplier: Int }

let readsMultiplier: Writer<[String], Reader<Config, Int>> =
    Writer(Reader { $0.multiplier }, ["reads multiplier"])
readsMultiplier.writerT.map { $0 * 2 }  // WriterTReader<[String], Config, Int>
```

### `OptionalTWriter` (wraps `Writer<W, A>?`, outer = Optional, inner = Writer)

```swift
let maybeLogged: Writer<[String], Int>? = .some(Writer(42, ["log"]))
maybeLogged.optionalT.map { $0 * 2 }.rawValue   // Optional(Writer(84, ["log"]))

// WriterT bind: the continuation may fail (nil) as well as log
maybeLogged.optionalT.flatMap { n in OptionalTWriter(n > 0 ? Writer(n / 2, ["halved"]) : nil) }.rawValue
// Optional(Writer(21, ["log", "halved"]))
```

### `ArrayTWriter` (wraps `[Writer<W, A>]`, outer = Array, inner = Writer)

```swift
let ws: [Writer<[String], Int>] = [Writer(1, ["a"]), Writer(2, ["b"])]
ws.arrayT.map { $0 * 10 }.rawValue  // [Writer(10, ["a"]), Writer(20, ["b"])]

// WriterT bind: each element's log prefixes the logs of its branches
ws.arrayT.flatMap { n in ArrayTWriter([Writer(n, ["x"]), Writer(-n, ["y"])]) }.rawValue
// [Writer(1, ["a", "x"]), Writer(-1, ["a", "y"]), Writer(2, ["b", "x"]), Writer(-2, ["b", "y"])]
```

The escape hatch (whole nested value in, new nested value out) is `mapWriterT` (Haskell's name) on
`ArrayTWriter`, `OptionalTWriter`, `EitherTWriter`, `ResultTWriter` and on the Writer-outer stacks,
except Writer outside Optional / Either / Result, where it's named after the inner layer
(`mapMaybeT`, `mapExceptT`). Reader / Stateful / stream outer layers keep their own name
(`ReaderTWriter.mapReaderT`, `StatefulTWriter.mapStateT`, `PublisherTWriter.mapPublisherT`).

---

## Module

```swift-sketch
import DataStructure          // Writer type, named functions and the WriterT* / *TWriter stack structs
import DataStructureOperators // Operators (<£>, <*>, >>-, ->>, <<<…), also for the stacks
```

---

## For Haskell developers

| This library | Haskell equivalent |
|---|---|
| `Writer<W: Monoid, A>` | `mtl`'s `Writer w a` (`Control.Monad.Writer`) |
| `<£>` / `<&>` (`fmap`) | `fmap` / `<$>` |
| `<*>` | `Applicative`'s `<*>` (logs combined via `Monoid`) |
| `>>-` / `-<<` (`flatMap`) | `>>=` / `=<<` |
| `>=>` | `Control.Monad`'s `>=>` |
| `pure` | `Applicative`'s `pure` / `return` (empty log) |
| `tell` | `MonadWriter`'s `tell` — exact naming parallel |
| `listen` | `MonadWriter`'s `listen` — exact naming parallel |
| `censor` | `MonadWriter`'s `censor` — exact naming parallel |
| `WriterT{Inner}` / `{Outer}TWriter` stacks | `mtl`'s `WriterT w m a` |

`Writer`'s `Comonad` instance (`extract`/`extend`/`duplicate`) corresponds to the `comonad` package's instance for `(,) w` — and unlike `Reader`, it needs **no extra constraint** beyond what this library already requires: `Writer`'s `W: Monoid` bound exists for `pure`/`flatMap`, not specifically for comonadic operations, so the `Comonad` instance here comes for free. This mirrors Haskell, where `(,) w`'s `Comonad` instance is unconditional (no `Semigroup`/`Monoid` needed at all) — a rare case where this library's constraint is actually *stricter* than Haskell's, simply because `W: Monoid` is already baked into the type.

External references:
- [`Control.Monad.Writer`](https://hackage.haskell.org/package/mtl/docs/Control-Monad-Writer.html) — the `mtl` module this type mirrors
- Wadler, ["Monads for functional programming"](https://homepages.inf.ed.ac.uk/wadler/papers/marktoberdorf/baastad.pdf) — the classic paper that uses the Writer monad (as a logging/accumulation example) to motivate monadic programming
