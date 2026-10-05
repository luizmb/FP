# Monad Transformers

Stack two effects into one type (a `Reader` that can fail, a `Publisher` of optionals, a `Stateful`
that logs) and work on the value inside both layers with one `map`, one `flatMap` and the usual
operators.

## Overview

A monad transformer stack is a nested value treated as a single effect. `Reader<Config, Either<AppError, Int>>`
is a computation that needs a `Config` and can fail with an `AppError`, and most of the time you
want to work on the `Int` and let the two layers take care of themselves (pass the environment
along, stop at the first failure).

In this library every stack is its own struct, named after its layers outermost first:
`ReaderTEither<Config, AppError, Int>` wraps `Reader<Config, Either<AppError, Int>>`. There are 74
of them, all generated from one table, so they all have the same members in the same shape and
once you know one you know them all.

The examples below build on each other, the `swift` blocks compile when read top to bottom. They
use this setup:

```swift
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators

struct Config: Sendable {
    let token: String?
    let retries: Int
}

enum AppError: Error, Equatable {
    case missingToken
    case tooManyRetries(Int)
}

let config = Config(token: "abc", retries: 3)
```

## Why each stack is its own type

Look at the plain nested value first:

```swift
let retries: Reader<Config, Either<AppError, Int>> = Reader { .right($0.retries) }

// Reader's own map: the function gets the whole Either
let described = retries.map { either in either.map { "\($0) retries" } }
```

`retries` is a `Reader`, so `map` (and `<£>`, `>>-`, `<*>`) are the `Reader` ones and the function
receives the whole `Either`. That's correct, a `Reader` of something is still a `Reader`. Before
this design the library also had transformer overloads on the same nested types, so `<£>` on a
`Reader<Env, [A]>` could mean "map the array" or "map each element" depending on which overload
Swift ranked higher, and the transformer versions needed their own names (`mapT`, `flatMapT`,
`^`-suffixed operators) to be reachable at all.

Haskell never has this problem because `ReaderT r m a` is a `newtype`, a different type from
`r -> m a` with its own instances. Wrapping the nested value in a struct is the same trick:

```swift
// The stack's map: the function gets the Int
let doubled = retries.readerT.map { $0 * 2 }
```

The obvious next question is why there are 74 structs instead of one generic `ReaderT<Env, M, A>`.
Swift has no higher-kinded types, so a generic parameter can't be "a type constructor like
`Either<AppError, _>` or `Array<_>`", which means there is no way to write `ReaderT` once for every
inner monad `M` (the usual emulations need `as!`, which this library doesn't ship). Each
outer/inner pair is a concrete struct with its own `map` / `apply` / `flatMap`, generated so nobody
has to write them by hand.

### TransformerStack, MonadT, O and I

Every stack conforms to `TransformerStack`, and the ones with a lawful monad conform to its
refinement `MonadT`. Both protocols have two associated types:

- `O` is the whole nested value (`Reader<Config, Either<AppError, Int>>` for
  `ReaderTEither<Config, AppError, Int>`).
- `I` is the inner layer only (`Either<AppError, Int>`).

The only stored property is `rawValue: O`, and there are two initialisers, `init(rawValue:)` and
the unlabelled `init(_:)` (handy point-free). `TransformerStack` looks like `RawRepresentable` but
doesn't refine it, because with Swift 6.3 a generic `RawRepresentable` struct whose `RawValue` is an
`Optional` (every `OptionalT*` stack) breaks type inference of generic methods returning it.

The protocols are there for code that is generic over stacks:

```swift
func unwrapped<Stack: TransformerStack>(_ stack: Stack) -> Stack.O { stack.rawValue }
```

## Getting in and getting out

You get in with a lifting property named after the outer layer (`readerT`, `statefulT`,
`writerT`, `publisherT`, `asyncStreamT`, `arrayT`, `optionalT`, `resultT`, `eitherT`,
`validationT`, `nonEmptyT`), or with the initialiser. You get out with `rawValue`.

```swift
let stack: ReaderTEither<Config, AppError, Int> = retries.readerT
let sameStack = ReaderTEither(retries)
let nestedAgain: Reader<Config, Either<AppError, Int>> = stack.rawValue
let ran = stack.rawValue(config) // .right(3)

// Properties work as key paths
let stacks = [retries, retries].map(\.readerT)
```

The property picks the stack from the inner type (`reader.readerT` is a `ReaderTEither` when the
`Reader` holds an `Either`, a `ReaderTArray` when it holds an array, and so on). Swift has no
parameterised extensions, so the inner type is matched through small "inner-shape" protocols
(`ArrayLike`, `OptionalLike`, `EitherLike`, `ResultLike`, `WriterLike`, …) with a single conformer
each and identity requirements only, so lifting never copies or rebuilds anything.

There is no `lift` like Haskell's. To bring in only one layer, build the nested value with the
other layer trivial and lift that:

```swift
// Only the inner layer (Haskell's lift): an Either that ignores the environment
let failure: Either<AppError, Int> = .left(.missingToken)
let liftedInner = Reader<Config, Either<AppError, Int>> { _ in failure }.readerT

// Only the outer layer: a Reader whose result can't fail
let liftedOuter = Reader<Config, Either<AppError, Int>> { .right($0.retries) }.readerT

// A plain value: pure
let liftedValue = ReaderTEither<Config, AppError, Int>.pure(42)
```

## Functor, applicative and monad

Every operation exists as a named function on the struct and as an operator that delegates to it.
Use whichever reads better, they are the same thing.

| Operation | Named | Operator |
|---|---|---|
| map | `fa.map(f)`, `Stack.fmap(f)` | `f <£> fa`, `fa <&> f` |
| replace the value | `fa.map { _ in b }` | `fa £> b`, `b <£ fa` |
| pure | `Stack.pure(a)` | |
| apply | `Stack.apply(ff, fa)` | `ff <*> fa` |
| lift a binary function | `Stack.liftA2(f)(fa, fb)` | `f2 <£> fa <*> fb` (with `f2` curried) |
| sequence | `fa.seqRight(fb)`, `fa.seqLeft(fb)` | `fa *> fb`, `fa <* fb` |
| bind | `fa.flatMap(f)`, `Stack.bind(f)` | `fa >>- f`, `f -<< fa` |
| Kleisli | `Stack.kleisli(f, g)`, `Stack.kleisliBack(g, f)` | `f >=> g`, `g <=< f` |

`apply`, `liftA2`, `kleisli` and `pure` are static, on the stack type whose value is the result
(`apply`, `liftA2`, `pure`) or the middle value (`kleisli`).

Functor:

```swift
let plusOne = stack.map { $0 + 1 }
let plusOneOp = { $0 + 1 } <£> stack
let plusOneFlipped = stack <&> { $0 + 1 }
let done = stack £> "done"
```

Applicative:

```swift
let attempts = ReaderTEither<Config, AppError, Int>.pure(1)

let sum = ReaderTEither<Config, AppError, Int>.liftA2 { (lhs: Int, rhs: Int) in lhs + rhs }(stack, attempts)

let add: @Sendable (Int) -> @Sendable (Int) -> Int = { lhs in { rhs in lhs + rhs } }
let sumApply = ReaderTEither<Config, AppError, Int>.apply(stack.map(add), attempts)
let sumOp = add <£> stack <*> attempts

let keepRight = stack.seqRight(attempts)
let keepRightOp = stack *> attempts
```

Monad:

```swift
let checkRetries: @Sendable (Int) -> ReaderTEither<Config, AppError, Int> = { count in
    ReaderTEither(Reader { _ in count > 5 ? .left(.tooManyRetries(count)) : .right(count) })
}
let readToken: @Sendable (Int) -> ReaderTEither<Config, AppError, String> = { _ in
    ReaderTEither(Reader { config in config.token.map { .right($0) } ?? .left(.missingToken) })
}

let checked = stack.flatMap(checkRetries)
let checkedOp = stack >>- checkRetries

let pipeline = ReaderTEither<Config, AppError, Int>.kleisli(checkRetries, readToken)
let pipelineOp = checkRetries >=> readToken

let token = pipelineOp(3).rawValue(config) // .right("abc")
let tooMany = pipelineOp(9).rawValue(config) // .left(.tooManyRetries(9))
```

A `.left` anywhere stops the chain and the environment is passed to every step, which is what
you'd get from `ExceptT AppError (Reader Config)` in Haskell.

## Monad, applicative only, functor only

Not every pair of effects has a lawful monad. When a combination has one, the stack conforms to
`MonadT` and gets the whole table above. When it doesn't, it conforms only to `TransformerStack`
and stops at functor + applicative (like Haskell's `Compose`), and there is one stack
(`AsyncStreamTStateful`) that is a functor only. The missing members are missing on purpose, a
`flatMap` that compiles but breaks the monad laws is worse than no `flatMap`.

The combinations without a monad, and why:

- **`Validation` anywhere.** `Validation` is an accumulating applicative and never a monad (a
  bind would have to stop at the first failure and throw the other errors away, which is the whole
  thing `Validation` exists to avoid). Every `ValidationT*` stack and every stack with `Validation`
  inside (`ReaderTValidation`, `EitherTValidation`, `StatefulTValidation`, `WriterTValidation`)
  stops at applicative.
- **A list inside an outer effect that doesn't commute.** `EitherTArray`, `EitherTNonEmpty`,
  `StatefulTArray`, `StatefulTNonEmpty`, `WriterTArray`, `WriterTNonEmpty`, `PublisherTArray` and
  `AsyncStreamTArray`. Binding element by element runs the outer effect once per element, so
  associativity only holds when that effect commutes (with a `Writer` log, the two sides of the
  associativity law log in different orders). This is Haskell's old `ListT`, deprecated and later
  removed from `transformers` for this exact reason.
- **`Writer` outside another monad.** `WriterTReader`, `WriterTStateful`, `WriterTPublisher`,
  `WriterTAsyncStream` (and the `Array` / `NonEmpty` / `Validation` ones above). The log sits
  outside the effect, so a bind would need the continuation's log before running the effect, and
  there is no way to have it. Haskell's `WriterT w m` is `m (a, w)` with the log inside, which here
  is `ArrayTWriter`, `OptionalTWriter`, `ResultTWriter`, `EitherTWriter`, `ReaderTWriter`,
  `StatefulTWriter`, `PublisherTWriter`, `AsyncStreamTWriter`, all monads.
- **A monad outside `Stateful`.** `ArrayTStateful`, `OptionalTStateful`, `ResultTStateful`,
  `EitherTStateful`, `PublisherTStateful` and `AsyncStreamTStateful`. The outer layer is decided
  before the state runs, so the continuation can never reach it. Use `StatefulTOptional`,
  `StatefulTEither`, `StatefulTResult` or `StatefulTWriter` instead (state outside, failure or
  log inside).
- **`Stateful` outside `Reader`, `Publisher` or `AsyncStream`.** `StatefulTReader`,
  `StatefulTPublisher`, `StatefulTAsyncStream`. `Stateful` has to produce the next state before the
  inner effect runs, but the continuation needs the value that only exists after it runs (it needs
  the environment, or the stream to emit). For environment plus state use `ReaderTStateful`
  (`ReaderT r (State s)`).

An applicative-only stack still combines independent computations, and for `Validation` that's
exactly what you want (both errors come back):

```swift
struct Settings: Sendable {
    let token: String
    let retries: Int
}

let tokenCheck = ReaderTValidation<Config, [String], String>(Reader { config in
    config.token.map { .success($0) } ?? .failure(["token is missing"])
})
let retriesCheck = ReaderTValidation<Config, [String], Int>(Reader { config in
    config.retries <= 5 ? .success(config.retries) : .failure(["too many retries"])
})

let settings = ReaderTValidation<Config, [String], Settings>.liftA2 { (token: String, retries: Int) in
    Settings(token: token, retries: retries)
}(tokenCheck, retriesCheck)

let makeSettings: @Sendable (String) -> @Sendable (Int) -> Settings = { token in
    { retries in Settings(token: token, retries: retries) }
}
let settingsOp = makeSettings <£> tokenCheck <*> retriesCheck

let invalid = settingsOp.rawValue(Config(token: nil, retries: 9))
// .failure(["token is missing", "too many retries"])
```

`tokenCheck >>- …` doesn't compile, there is no `flatMap` on `ReaderTValidation`.

A functor-only stack has `map`, `fmap`, `<£>`, `<&>`, `£>`, `<£` and the escape hatch, nothing
else:

```swift
let ticks = AsyncStream<Stateful<Int, String>> { continuation in
    continuation.yield(Stateful { count in "tick \(count)" })
    continuation.finish()
}.asyncStreamT

let loud = ticks.map { $0.uppercased() }
let loudOp = { $0.uppercased() } <£> ticks
```

## Escape hatches

A stack only exposes the algebra (functor, applicative, monad). Everything else the underlying
types can do (`Reader.local`, Combine's `receive(on:)`, `Either.mapLeft`, `Writer.censor`, …) is
reached through one escape hatch per stack, a function `(O) -> O2` that gets the whole nested value
and returns a new one, rewrapped as the same kind of stack (the type parameters can change):

```swift
// Reader.local: run the stack with a modified environment
let doubleRetries = stack.mapReaderT { reader in
    reader.local { Config(token: $0.token, retries: $0.retries * 2) }
}

// Transform the inner layer: map over the Reader, then over the Either's left side
let stringErrors = stack.mapReaderT { reader in
    reader.map { either in either.mapLeft { "\($0)" } }
}
```

The names come from Haskell, picked in this order:

1. By the outer layer when it is `Reader`, `Stateful`, `Publisher` or `AsyncStream`:
   `mapReaderT`, `mapStateT`, `mapPublisherT`, `mapAsyncStreamT`.
2. Otherwise by the inner layer when it is `Optional`, `Either`/`Result` or `Writer`: `mapMaybeT`,
   `mapExceptT`, `mapWriterT` (so `WriterTEither` uses `mapExceptT`, and `EitherTWriter` uses
   `mapWriterT`).
3. Otherwise by the outer layer again: `mapArrayT`, `mapOptionalT`, `mapEitherT`, `mapResultT`,
   `mapValidationT`, `mapWriterT` (`WriterTArray`, `WriterTReader`, …).

`mapExceptT`, `mapMaybeT` and `mapWriterT` behave like their Haskell namesakes (in Haskell those
newtypes are the whole `m (…)` too). `mapReaderT` and `mapStateT` are a bit more powerful than
Haskell's, because they get the whole `Reader` / `Stateful` and can change the environment or the
state handling as well (Haskell needs `withReaderT` / `local` for the `doubleRetries` example above).

The streaming stacks are where this matters most, because Combine and `AsyncStream` have a huge
API that no stack should proxy:

```swift
import Combine
import Foundation

let page: PublisherTArray<Never, Int> = [1, 2, 3, 4].publisher.collect().publisherT

let onMain = page.mapPublisherT { publisher in
    publisher.receive(on: DispatchQueue.main).eraseToAnyPublisher()
}

let evens = page.mapPublisherT { publisher in
    publisher.map { numbers in numbers.filter { $0.isMultiple(of: 2) } }.eraseToAnyPublisher()
}
```

(`PublisherT*` stacks store an `AnyPublisher`, so the closure ends with `eraseToAnyPublisher()`.)

## The stacks

The name is `<Outer>T<Inner>`, and the Haskell transformer it corresponds to depends on the shape
of the nesting, not on the first word of the name:

| Shape | Haskell | Examples |
|---|---|---|
| `Reader<Env, M<A>>` | `ReaderT env m` | `ReaderTEither`, `ReaderTArray`, `ReaderTPublisher` |
| `M<A?>` | `MaybeT m` | `ReaderTOptional`, `StatefulTOptional`, `PublisherTOptional` |
| `M<Either<L, A>>`, `M<Result<A, E>>` | `ExceptT l m` | `WriterTEither`, `StatefulTResult`, `OptionalTResult` |
| `M<Writer<W, A>>` | `WriterT w m` | `ArrayTWriter`, `ResultTWriter`, `StatefulTWriter` |
| `F<G<A>>` without a lawful monad | `Compose f g` | `ValidationTArray`, `WriterTReader`, `ArrayTStateful` |

So `StatefulTEither` is `ExceptT l (State s)` (the state survives a failure), and there is no
`StateT s m` over an arbitrary `m`.

All 74 stacks, by outer layer (**M** = monad, **A** = applicative only, **F** = functor only):

| Outer | Inner layers |
|---|---|
| `Reader` | M: `Array`, `AsyncStream`, `Either`, `NonEmpty`, `Optional`, `Publisher`, `Reader`, `Result`, `Stateful`, `Writer`. A: `Validation` |
| `Stateful` | M: `Either`, `Optional`, `Result`, `Writer`. A: `Array`, `AsyncStream`, `NonEmpty`, `Publisher`, `Reader`, `Validation` |
| `Writer` | M: `Either`, `Optional`, `Result`. A: `Array`, `AsyncStream`, `NonEmpty`, `Publisher`, `Reader`, `Stateful`, `Validation` |
| `Either` | M: `Optional`, `Result`, `Writer`. A: `Array`, `NonEmpty`, `Stateful`, `Validation` |
| `Validation` | A: `Array`, `Either`, `NonEmpty`, `Optional`, `Reader`, `Result`, `Stateful`, `Writer` |
| `Optional` | M: `Array`, `Either`, `NonEmpty`, `Result`, `Writer`. A: `Stateful` |
| `Array` | M: `Either`, `Optional`, `Result`, `Writer`. A: `Stateful` |
| `NonEmpty` | M: `Either`, `Optional`, `Result` |
| `Result` | M: `Writer`. A: `Stateful` |
| `Publisher` | M: `Either`, `Optional`, `Result`, `Writer`. A: `Array`, `Stateful` |
| `AsyncStream` | M: `Either`, `Optional`, `Result`, `Writer`. A: `Array`. F: `Stateful` |

Nestings that are missing (`[[A]]`, `Result<[A], E>`, `Result<Either<L, A>, E>`, …) aren't stacks,
those only get `sequence` / `traverse` on the nested type.

Stacks whose layers are all `CoreFP` types (`Array`, `Optional`, `Result`, `Publisher`,
`AsyncStream`) live in `CoreFP` with operators in `CoreFPOperators`, everything else lives in
`DataStructure` with operators in `DataStructureOperators`. The sources are under
`Sources/<Module>/Transformer/Generated/`, one file per stack plus one for its operators.

`PublisherT*` stacks wrap an `AnyPublisher`, `AsyncStreamT*` stacks wrap an `AsyncStream`, and
`ReaderTPublisher` wraps `Reader<Env, any Publisher<A, E>>`. Streams follow Haskell's stream
semantics (`pipes`, `conduit`, `fs2`): bind is ordered concat (each inner stream runs to the end,
in upstream order, nothing dropped), and the applicative is `ap`, where each left element runs over
the whole right stream like the list applicative (zip is a different thing, use `zip` for that).
The right stream is single-pass, so `ap` buffers it once and replays it, which means it has to be
finite.

## Adding a stack

Never edit the generated files by hand, the generator wipes and rewrites the `Generated`
directories on every run. To add a stack:

1. Add one line to `inventory` in `Scripts/GenerateTransformers.swift`, e.g.
   `Stack(.reader, .either, .monad)`. The kind is `.monad` (lawful monad, `MonadT`),
   `.applicative` (`TransformerStack` with functor + applicative) or `.functor`. Only pick
   `.monad` if you can show the laws hold (see the reasons above for the usual ways they don't).
2. The generated members delegate to the internal nested-type functions by name (`mapT`,
   `apply<Outer><Inner>`, `liftA2<Outer><Inner>`, `seqRight…`, `seqLeft…`, `flatMapT`), so those
   have to exist. When a stack's functions don't follow that pattern, add an `Override`
   (`.applyViaLiftA2`, `.freeFlatMap`, or a custom `.map` / `.liftA2` / `.flatMap` / `.pure` body).
3. Run `swift Scripts/GenerateTransformers.swift` from the package root, then
   `mint run swiftformat --lint .` (the output is already formatted, this must stay clean), and
   commit the regenerated sources together with the script change.

A new layer type (something that isn't in `Layer` yet) needs a `Layer` case with its type,
parameters, `pure` and lifting extension and, if it can be an inner layer, an inner-shape protocol.
`CONTRIBUTING.md` ("Transformer stacks") has the full checklist.

## Further reading

- [`transformers` on Hackage](https://hackage.haskell.org/package/transformers): `ReaderT`,
  `WriterT`, `StateT`, `ExceptT`, `MaybeT`.
- [Martin Grabmüller, *Monad Transformers Step by Step*](https://page.mi.fu-berlin.de/scravy/realworldhaskell/materialien/monad-transformers-step-by-step.pdf),
  the classic tutorial that builds a stack one layer at a time.
