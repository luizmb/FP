# Writer

`Writer<W: Monoid, A>` is a pair of a value `A` and a log `W`.

It solves the **accumulating output** problem: instead of threading a log or accumulator through every function manually, you describe computations that *produce* a value and *append* to a log simultaneously. The log entries are collected automatically as computations are chained. The log type `W` must be a `Monoid` so the library knows how to combine entries and what the empty log looks like.

```swift
import DataStructure

// A computation that produces 42 and logs a message
let w = Writer(42, ["computed the answer"])

w.value        // 42
w.log          // ["computed the answer"]
w.runWriter()  // (42, ["computed the answer"])
w.evalWriter() // 42
w.execWriter() // ["computed the answer"]
```

---

## `<£>` and `<&>` — Map

Transform the value without touching the log.

```swift
{ $0 * 2 } <£> Writer(21, ["step 1"])   // Writer(42, ["step 1"])
Writer(21, ["step 1"]) <&> { $0 * 2 }  // Writer(42, ["step 1"])

// Named functions
Writer(21, ["step 1"]).mapWriter { $0 * 2 }
Writer(21, ["step 1"]).fmap { $0 * 2 }
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
Writer({ $0 * 2 }, ["fn loaded"]) <*> Writer(21, ["value ready"])
// Writer(42, ["fn loaded", "value ready"])

// Named functions
Writer.apply(Writer({ $0 * 2 }, ["fn"]), Writer(21, ["val"]))
// Writer(42, ["fn", "val"])

Writer.zip(Writer(1, ["a"]), Writer(2, ["b"]))
// Writer((1, 2), ["a", "b"])

Writer.liftA2(+)(Writer(10, ["x"]), Writer(32, ["y"]))
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
Writer(6, ["start"])
    >>- { n in Writer(n * 7, ["multiplied by 7"]) }
// Writer(42, ["start", "multiplied by 7"])

Writer(2, ["a"])
    >>- { n in Writer(n + 10, ["added 10"]) }
    >>- { n in Writer(n * 2, ["doubled"]) }
// Writer(24, ["a", "added 10", "doubled"])

// Named functions
Writer(6, ["start"]).flatMap { n in Writer(n * 7, ["x7"]) }
Writer.bind { n in Writer(n * 2, ["x2"]) }(Writer(21, ["init"]))
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Writer`.

```swift
let parse:    (String) -> Writer<[String], Int>    = { s in Writer(Int(s) ?? 0, ["parsed"]) }
let validate: (Int)    -> Writer<[String], Int>    = { n in Writer(max(0, n), ["validated"]) }
let format:   (Int)    -> Writer<[String], String> = { n in Writer("Result: \(n)", ["formatted"]) }

let pipeline = parse >=> validate >=> format
pipeline("42").runWriter()  // ("Result: 42", ["parsed", "validated", "formatted"])

// Named function
Writer.kleisli(parse, validate)("42")
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
    Writer.tell(["start"]) *>
    Writer(42, ["computed"]) >>- { n in
        Writer.tell(["result: \(n)"]) *> .pure(n)
    }
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
extend { w in w.value * 2 }(Writer(21, ["x"]))  // Writer(42, ["x"])

// Operators
Writer(21, ["x"]) ->> { $0.value * 2 }   // Writer(42, ["x"])
{ $0.value * 2 } <<- Writer(21, ["x"])   // Writer(42, ["x"])
```

---

## Traversable

`Writer` is Traversable when its value is a container. These operations "flip" the nesting.

```swift
// WriterTArray — Writer<W, [A]> → [Writer<W, A>]
Writer(["a", "b", "c"], ["log"]).sequence()
// [Writer("a", ["log"]), Writer("b", ["log"]), Writer("c", ["log"])]

Writer([1, 2, 3], []).traverse { [$0, $0 * 10] }
// [Writer(1,[]), Writer(10,[]), Writer(2,[]), Writer(20,[]), Writer(3,[]), Writer(30,[])]

// WriterTOptional — Writer<W, A?> → Writer<W, A>?
Writer(Optional(42), ["log"]).sequence()    // Optional(Writer(42, ["log"]))
Writer(Optional<Int>.none, ["log"]).sequence()  // nil

// WriterTResult — Writer<W, Result<A,E>> → Result<Writer<W,A>, E>
Writer(Result<Int, MyError>.success(42), ["log"]).sequence()
// .success(Writer(42, ["log"]))

Writer(Result<Int, MyError>.failure(.bad), ["log"]).sequence()
// .failure(.bad)

// Free function variants
sequence(Writer([1, 2], ["log"]))   // [Writer(1, ["log"]), Writer(2, ["log"])]
traverse { [$0, $0 * 2] }(Writer(5, ["log"]))  // [Writer(5, ["log"]), Writer(10, ["log"])]
```

---

## Monad Transformers

Writer participates in transformer stacks either as the **outer** layer or as the **inner** layer.

### `WriterTOptional` — `Writer<W, A?>` (outer = Writer, inner = Optional)

Log accumulates regardless of whether a value is present.

```swift
let w: Writer<[String], Int?> = Writer(.some(5), ["found"])
{ $0 * 2 } <£^> w   // Writer(Optional(10), ["found"])

let empty: Writer<[String], Int?> = Writer(.none, ["not found"])
{ $0 * 2 } <£^> empty  // Writer(nil, ["not found"])
```

### `WriterTEither` — `Writer<W, Either<L, A>>` (outer = Writer, inner = Either)

```swift
let w: Writer<[String], Either<String, Int>> = Writer(.right(5), ["ok"])
{ $0 * 2 } <£^> w   // Writer(.right(10), ["ok"])

let fail: Writer<[String], Either<String, Int>> = Writer(.left("err"), ["failed"])
{ $0 * 2 } <£^> fail  // Writer(.left("err"), ["failed"])
```

### `WriterTResult` — `Writer<W, Result<A, E>>` (outer = Writer, inner = Result)

```swift
let w: Writer<[String], Result<Int, MyError>> = Writer(.success(5), ["ok"])
{ $0 * 2 } <£^> w   // Writer(.success(10), ["ok"])
```

### `WriterTStateful` — `Writer<W, Stateful<S, A>>` (outer = Writer, inner = Stateful)

Produces a stateful computation alongside a log entry. Useful when you want to record that a state transition happened.

```swift
let w: Writer<[String], Stateful<Int, Int>> =
    Writer(Stateful { s in s += 1; return s }, ["will increment"])
{ $0 * 2 } <£^> w  // Writer<[String], Stateful<Int, Int>> — doubles the result
```

### `WriterTReader` — `Writer<W, Reader<Env, A>>` (outer = Writer, inner = Reader)

```swift
let w: Writer<[String], Reader<Config, Int>> =
    Writer(Reader { $0.multiplier }, ["reads multiplier"])
{ $0 * 2 } <£^> w  // Writer<[String], Reader<Config, Int>>
```

### `OptionalTWriter` — `Writer<W, A>?` (outer = Optional, inner = Writer)

```swift
let w: Writer<[String], Int>? = .some(Writer(42, ["log"]))
w?.fmap { $0 * 2 }   // Optional(Writer(84, ["log"]))
```

### `ArrayTWriter` — `[Writer<W, A>]` (outer = Array, inner = Writer)

```swift
let ws: [Writer<[String], Int>] = [Writer(1, ["a"]), Writer(2, ["b"])]
ws.map { $0.fmap { $0 * 10 } }  // [Writer(10, ["a"]), Writer(20, ["b"])]
```

---

## Module

```swift
import DataStructure          // Writer type + named functions
import DataStructureOperators // Operators (<£>, <*>, >>-, ->>, <<<…)
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
