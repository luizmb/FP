# Monad Transformers

A monad transformer stacks two effects into one type, so you can work with both at once, for
example a computation that can fail (`Either`) *and* produce multiple results (`Array`), or one
that needs an environment (`Reader`) *and* might be absent (`Optional`).

This library gives every stack its own struct, named `OuterTInner`. `WriterTEither<W, L, A>` wraps
`Writer<W, Either<L, A>>` (the outer type wraps the inner type, and the capital `T` reads as
"transformed with" or, if you like your Haskell, as the `T` suffix in `ReaderT`/`WriterT`/`StateT`).
`EitherTResult<L, E, A>` wraps `Either<L, Result<A, E>>`: outer `Either`, inner `Result`.

```swift
import DataStructure

// A plain nested value is just a Writer (its map / >>- are the Writer ones)
let nested: Writer<[String], Either<String, Int>> = Writer(.right(5), ["ok"])

// Wrapped, it's the WriterTEither stack: map / flatMap / operators reach the Int
let stack: WriterTEither<[String], String, Int> = nested.writerT   // or WriterTEither(nested)
let doubled = stack.map { $0 * 2 }
doubled.rawValue  // Writer(.right(10), ["ok"])
```

---

## The shape of a stack

Every stack struct has the same surface:

- `rawValue` (the whole nested value), `init(rawValue:)` and the unlabelled `init(_:)`.
- Functor: `map`, static `fmap`; operators `<£>`, `<&>`, `£>`, `<£`.
- Applicative: static `pure`, static `apply`, static `liftA2`, `seqRight`, `seqLeft`; operators
  `<*>`, `*>`, `<*`.
- Monad (only stacks with a lawful monad, which conform to `MonadT`): `flatMap`, static `bind`,
  static `kleisli` / `kleisliBack`; operators `>>-`, `-<<`, `>=>`, `<=<`.
- An escape hatch `(O) -> O2` that hands you the whole nested value, so the full API of the
  underlying types (Combine's `receive(on:)`, `Stateful.modify`, …) is reachable without the stack
  proxying it. Names follow Haskell: `mapReaderT`, `mapStateT`, `mapPublisherT`,
  `mapAsyncStreamT` (named by the outer layer), `mapMaybeT`, `mapExceptT`, `mapWriterT` (named by
  the inner layer), and for Compose-like stacks the outer name again (`mapArrayT`, `mapOptionalT`,
  `mapEitherT`, `mapResultT`, `mapValidationT`). `stack.mapReaderT { $0.local(f) }` is Haskell's
  `mapReaderT`, and `mapXT` with an inner `map` covers "transform the inner layer".

Getting in and out:

```swift
let reader: Reader<Config, [User]> = loadUsers

reader.readerT                 // ReaderTArray<Config, User>, via the lifting property
ReaderTArray(reader)           // same thing
reader.readerT.rawValue        // back to Reader<Config, [User]>
```

The lifting property is named after the outer type (`readerT`, `statefulT`, `writerT`,
`publisherT`, `asyncStreamT`, `arrayT`, `optionalT`, `resultT`, `eitherT`, `validationT`,
`nonEmptyT`) and picks the stack from the inner type. Swift has no parameterized extensions, so the
inner type is matched through one-conformer "inner-shape" protocols (`ArrayLike`,
`OptionalLike`, `ResultLike`, `AsyncStreamLike`, `EitherLike`, `NonEmptyLike`, `WriterLike`,
`ValidationLike`, `ReaderLike`, `StatefulLike`) whose requirements are all the identity, so lifting
never copies anything. Being properties, they work as key paths (`users.map(\.readerT)`).

The protocols `TransformerStack` (`O` is the nested value, `I` its inner layer) and `MonadT`
let you write code generic over stacks. `TransformerStack` mirrors `RawRepresentable` but doesn't
refine it (with Swift 6.3, a generic `RawRepresentable` struct whose `RawValue` is an `Optional`
breaks type inference of every generic method returning it).

---

## Why every combination is its own type

In Haskell, a monad transformer is generic: `ReaderT r m a` works for *any* inner monad `m`,
because `ReaderT` is parameterised over a type constructor (`m :: * -> *`) and Haskell's
higher-kinded types let `Monad m => Monad (ReaderT r m)` be derived once, for every `m`.

Swift has no higher-kinded types, you cannot write `protocol MonadTransformer { associatedtype Inner<A> }`
and have it mean anything. A generic parameter in Swift is always a concrete type, never "a generic
type applied to something else." So there is no way to express "`Writer<W, Inner<A>>` is a `Monad`
whenever `Inner` is a `Monad`" as a single piece of code, and every outer/inner pairing needs its
own concrete type with its own `map` / `apply` / `flatMap`. This is the same limitation that rules
out a shared `Functor`/`Monad` protocol for the base types (see the library's "Swift Limitations"
notes), it just shows up again, multiplied, at the transformer level: instead of one `Monad`
instance per type, you need one per *pair* of types.

Wrapping each stack in a struct (Haskell's `newtype`) instead of using the nested type directly is
what keeps the operators honest: `Reader<Env, [A]>` is a `Reader`, so `<£>` on it maps the whole
array, while `ReaderTArray<Env, A>` maps each element. No `T`-suffixed names, no extra operators, and
no overload ranking deciding which meaning you get.

The 74 stacks are generated from a table by a dev-time script (`Scripts/GenerateTransformers.swift`),
so all of them expose the same members in the same shape; once you know the convention,
`ReaderTValidation`, `StatefulTWriter`, `EitherTNonEmpty`, … are all discoverable by name.

---

## Module placement

- If **either side** of the stack is a `DataStructure` type (`Either`, `Validation`, `Reader`,
  `Stateful`, `Writer` or `NonEmpty`) the struct lives in `DataStructure` and its operators in
  `DataStructureOperators`.
- If **both sides** are Swift built-ins or plain `CoreFP` types (`Array`, `Optional`, `Result`,
  `AsyncStream`, `Publisher`) the struct lives in `CoreFP` and its operators in `CoreFPOperators`.

The generated sources live in `Sources/<Module>/Transformer/Generated/`, one file per stack
(`ReaderTArray.swift`, `ReaderTArray+Operators.swift`).

---

## Transformer coverage matrix

**F** = Functor (`map`), **A** = Applicative (`pure` / `apply` / `liftA2`), **M** = Monad
(`flatMap`, conforms to `MonadT`). Stream stacks wrap `AnyPublisher` (`PublisherT*`) or
`AsyncStream` (`AsyncStreamT*`).

### CoreFP combinations (both sides built-in / CoreFP)

| Stack | Wraps | F | A | M |
|---|---|---|---|---|
| `OptionalTArray` | `[A]?` | Yes | Yes | Yes |
| `OptionalTResult` | `Result<A, E>?` | Yes | Yes | Yes |
| `ArrayTOptional` | `[A?]` | Yes | Yes | Yes |
| `ArrayTResult` | `[Result<A, E>]` | Yes | Yes | Yes |
| `AsyncStreamTOptional` | `AsyncStream<A?>` | Yes | Yes | Yes |
| `AsyncStreamTArray` | `AsyncStream<[A]>` | Yes | Yes | No |
| `AsyncStreamTResult` | `AsyncStream<Result<A, E>>` | Yes | Yes | Yes |
| `PublisherTOptional` | `AnyPublisher<A?, Failure>` | Yes | Yes | Yes |
| `PublisherTArray` | `AnyPublisher<[A], Failure>` | Yes | Yes | No |
| `PublisherTResult` | `AnyPublisher<Result<A, E>, Failure>` | Yes | Yes | Yes |

`ArrayTArray`, `OptionalTOptional`, `ResultTArray` and `ResultTOptional` are not stacks: those
nestings only get `Traversable` (`sequence` / `traverse`), flattening nested containers.

### `Either` combinations

| Stack | F | A | M |
|---|---|---|---|
| `EitherTArray` | Yes | Yes | No |
| `EitherTOptional` | Yes | Yes | Yes |
| `EitherTResult` | Yes | Yes | Yes |
| `EitherTValidation` | Yes | Yes | No |
| `EitherTStateful` | Yes | Yes | No |
| `EitherTWriter` | Yes | Yes | Yes |
| `EitherTNonEmpty` | Yes | Yes | No |
| `ArrayTEither` | Yes | Yes | Yes |
| `OptionalTEither` | Yes | Yes | Yes |
| `AsyncStreamTEither` | Yes | Yes | Yes |
| `PublisherTEither` | Yes | Yes | Yes |
| `NonEmptyTEither` | Yes | Yes | Yes |

`Result<Either<…>, E>` only gets `Traversable`. `EitherTValidation` has no Monad, see below.

### `Validation` combinations

Validation is an accumulating Applicative and, by design, **never** a Monad (see "Why some
combos lack a Monad" below). Every `Validation` combination therefore stops at F/A:

| Stack | F | A |
|---|---|---|
| `ValidationTArray` | Yes | Yes |
| `ValidationTOptional` | Yes | Yes |
| `ValidationTResult` | Yes | Yes |
| `ValidationTEither` | Yes | Yes |
| `ValidationTReader` | Yes | Yes |
| `ValidationTStateful` | Yes | Yes |
| `ValidationTWriter` | Yes | Yes |
| `ValidationTNonEmpty` | Yes | Yes |

`Result<Validation<…>, E>` only gets `Traversable`.

### `Reader` combinations

| Stack | F | A | M |
|---|---|---|---|
| `ReaderTArray` | Yes | Yes | Yes |
| `ReaderTOptional` | Yes | Yes | Yes |
| `ReaderTResult` | Yes | Yes | Yes |
| `ReaderTEither` | Yes | Yes | Yes |
| `ReaderTValidation` | Yes | Yes | No |
| `ReaderTReader` | Yes | Yes | Yes |
| `ReaderTStateful` | Yes | Yes | Yes |
| `ReaderTWriter` | Yes | Yes | Yes |
| `ReaderTAsyncStream` | Yes | Yes | Yes |
| `ReaderTPublisher` | Yes | Yes | Yes |
| `ReaderTNonEmpty` | Yes | Yes | Yes |

### `Stateful` combinations

| Stack | F | A | M |
|---|---|---|---|
| `StatefulTArray` | Yes | Yes | No |
| `StatefulTOptional` | Yes | Yes | Yes |
| `StatefulTResult` | Yes | Yes | Yes |
| `StatefulTEither` | Yes | Yes | Yes |
| `StatefulTValidation` | Yes | Yes | No |
| `StatefulTReader` | Yes | Yes | No |
| `StatefulTWriter` | Yes | Yes | Yes |
| `StatefulTNonEmpty` | Yes | Yes | No |
| `StatefulTPublisher` | Yes | Yes | No |
| `StatefulTAsyncStream` | Yes | Yes | No |
| `ArrayTStateful` | Yes | Yes | No |
| `OptionalTStateful` | Yes | Yes | No |
| `ResultTStateful` | Yes | Yes | No |
| `PublisherTStateful` | Yes | Yes | No |
| `AsyncStreamTStateful` | Yes | No | No |

### `Writer` combinations

| Stack | F | A | M |
|---|---|---|---|
| `WriterTArray` | Yes | Yes | No |
| `WriterTOptional` | Yes | Yes | Yes |
| `WriterTResult` | Yes | Yes | Yes |
| `WriterTEither` | Yes | Yes | Yes |
| `WriterTValidation` | Yes | Yes | No |
| `WriterTReader` | Yes | Yes | No |
| `WriterTStateful` | Yes | Yes | No |
| `WriterTNonEmpty` | Yes | Yes | No |
| `WriterTPublisher` | Yes | Yes | No |
| `WriterTAsyncStream` | Yes | Yes | No |
| `ArrayTWriter` | Yes | Yes | Yes |
| `OptionalTWriter` | Yes | Yes | Yes |
| `ResultTWriter` | Yes | Yes | Yes |
| `PublisherTWriter` | Yes | Yes | Yes |
| `AsyncStreamTWriter` | Yes | Yes | Yes |

### `NonEmpty` combinations

| Stack | F | A | M |
|---|---|---|---|
| `NonEmptyTEither` | Yes | Yes | Yes |
| `NonEmptyTOptional` | Yes | Yes | Yes |
| `NonEmptyTResult` | Yes | Yes | Yes |
| `OptionalTNonEmpty` | Yes | Yes | Yes |

(The remaining `NonEmpty` combinations, `EitherTNonEmpty`, `ValidationTNonEmpty`, `ReaderTNonEmpty`,
`StatefulTNonEmpty` and `WriterTNonEmpty`, are listed under their outer type above.)

**Streams follow Haskell stream semantics** (`pipes`/`conduit`/`fs2`): bind is ordered concat
(each inner stream runs to completion, in upstream order, nothing dropped), and every applicative
over a stream (`AsyncStream` itself, `AsyncStreamTOptional`/`Result`/`Either`/`Array`/`Writer`,
`PublisherT*`, `ReaderTAsyncStream`, `StatefulTAsyncStream`, `StatefulTPublisher`,
`WriterTAsyncStream`, `WriterTPublisher`) is `ap`: each left element runs over the whole right
stream, like the list applicative. It is not zip (`AsyncStream.zip` / Combine's `zip` pair
positionally). The right stream is single-pass, so `ap` drains it once into a buffer and replays it
(`AsyncStream.replayable(_:)`), which means it must be finite. `pure` on `ReaderTAsyncStream` and
`StatefulTAsyncStream` builds a fresh stream on every run, so running the stack twice works.

---

## Why some combos lack a Monad

**`Validation`: no Monad, anywhere, by design.** `Validation<E, A>` doesn't have a `flatMap` at
all, on the base type or on any stack. Its `Applicative` instance combines errors from *both*
sides via `Semigroup` when it can, the whole point of the type is to collect every validation
failure in one pass. A `flatMap` would have to pick a single branch to continue with in the failure
case, throwing away every error but the first. So `Validation` and every `ValidationT*` stack stop
at Functor + Applicative.

**A list inside a non-commutative outer layer: no Monad (Haskell's `ListT` done wrong).**
`EitherTArray`, `EitherTNonEmpty`, `StatefulTArray`, `StatefulTNonEmpty`, `WriterTArray`,
`WriterTNonEmpty`, `PublisherTArray` and `AsyncStreamTArray` (`M<[A]>` / `M<NonEmpty<A>>`) stop
at Functor + Applicative. Binding element by element runs the outer effect once per element, so
associativity only holds when that effect commutes. With a `Writer` log, `(m >>= f) >>= g` logs
`["m", "f1", "f2", "g10", "g20"]` while `m >>= (f >=> g)` logs `["m", "f1", "g10", "f2", "g20"]`.
Haskell's `transformers` deprecated (and later removed) `ListT` for exactly this reason.

**`Writer` outside another monad: no Monad (no distributive law).** `WriterTReader`,
`WriterTStateful`, `WriterTPublisher` and `WriterTAsyncStream` (`Writer<W, M<A>>`) stop at
Functor + Applicative. The log sits outside the effect, so a bind would have to know the
continuation's log before running `M`, which it can't (dropping that log instead breaks left
identity). Haskell's `WriterT` is `M<Writer<W, A>>` (the log inside), which this library ships as
`ArrayTWriter`, `OptionalTWriter`, `ResultTWriter`, `EitherTWriter`, `ReaderTWriter`,
`PublisherTWriter`, `StatefulTWriter`, … Their `flatMap` is WriterT's: the continuation returns
the whole stack (`(A) -> ArrayTWriter<W, B>`, `(A) -> OptionalTWriter<W, B>`, …), so it can fail
or branch as well as log.

**A monad outside `Stateful`: no Monad.** `ArrayTStateful`, `OptionalTStateful`,
`ResultTStateful`, `EitherTStateful`, `PublisherTStateful` and `AsyncStreamTStateful`
(`M<Stateful<S, A>>`) stop at Functor + Applicative (`AsyncStreamTStateful` at Functor). The
outer layer is decided before the state runs, so a continuation can never reach it (the best a
"bind" can do is `fmap(Stateful.flatMap)`). Haskell has no transformer of this shape; use
`StatefulTOptional` / `StatefulTEither` / `StatefulTResult` / `StatefulTWriter`
(`MaybeT`/`ExceptT`/`WriterT` over `State`) instead.

**`Stateful` outside `Reader`/`Publisher`/`AsyncStream`: no Monad.** `StatefulTReader`,
`StatefulTPublisher` and `StatefulTAsyncStream` (`Stateful<S, M<A>>`) stop at Functor +
Applicative. `Stateful` runs with `inout S`, which can't be captured by the escaping `Reader`,
Combine or async closures a bind would need. Thread the state around the stream instead, or use
`StatefulTResult` / `StatefulTEither` where sequencing is needed.

---

## A worked example: `EitherTResult`

`Either<L, Result<A, E>>` models two independent error channels, for example a routing/left-right
outcome (`Either`) wrapping a Swift-idiomatic fallible operation (`Result`). Wrap it once and
compose across both layers with the struct's methods or operators:

```swift
import DataStructure
import DataStructureOperators

enum MyError: Error { case negative }

let ok = EitherTResult<String, MyError, Int>(.right(.success(21)))

// map: transform the innermost value, leaving both outer layers alone
ok.map { $0 * 2 }.rawValue  // .right(.success(42))

// flatMap: chain a step that returns the whole stack
let nonNegative: @Sendable (Int) -> EitherTResult<String, MyError, Int> = { n in
    EitherTResult(n >= 0 ? .right(.success(n)) : .right(.failure(.negative)))
}
ok.flatMap(nonNegative).rawValue  // .right(.success(21))
(ok >>- nonNegative).rawValue     // same, via the operator

// kleisli: compose two steps that each return the stack
let parse: @Sendable (String) -> EitherTResult<String, MyError, Int> = { s in
    EitherTResult(Int(s).map { .right(.success($0)) } ?? .left("not a number"))
}
let double: @Sendable (Int) -> EitherTResult<String, MyError, Int> = { n in .pure(n * 2) }

let pipeline = parse >=> double
pipeline("21").rawValue    // .right(.success(42))
pipeline("nope").rawValue  // .left("not a number")

// escape hatch: the whole Either<String, Result<Int, MyError>> (inner-named, Haskell's mapExceptT)
let shouted: EitherTResult<String, MyError, Int> = ok.mapExceptT { $0.mapLeft { $0.uppercased() } }
```

A `.left` short-circuits immediately (the outer `Either` layer), a `.right(.failure(_))`
short-circuits the inner `Result` while staying `.right`, and only `.right(.success(_))` continues
the chain, the semantics you'd expect from stacking two short-circuiting monads.

---

## For Haskell developers

The concept maps directly onto `mtl`/`transformers`: `ReaderTReader`, `ReaderTResult`,
`WriterTEither`, `StatefulTEither`, and friends are this library's answer to `ReaderT`, `WriterT`,
`StateT` and `ExceptT`. Each struct is a `newtype` over the nested value (`rawValue` is the
`runReaderT`-style field), `map` is `fmap` through the stack, `flatMap` is `>>=`, `kleisli` is
`>=>`, and `mapReaderT` / `mapStateT` / `mapMaybeT` / `mapExceptT` / `mapWriterT` keep their
Haskell names.

The difference is mechanical, not conceptual: in Haskell, `ReaderT r m a` is `r -> m a` for *any*
monad `m`, and `Monad m => Monad (ReaderT r m)` is one instance declaration that covers every
possible `m` because `m` is a higher-kinded type parameter. Here, `ReaderTResult`, `ReaderTEither`,
`ReaderTWriter`, etc. are separate concrete structs (generated, so they all look alike), because
Swift generics cannot abstract over "a type that itself takes a type parameter." The coverage
matrix above is the price of that gap. There is no `lift` either: you lift a whole nested value
with the property (`reader.readerT`) or `pure` a plain one.

For the Haskell side of this mapping, see:
- [`transformers` on Hackage](https://hackage.haskell.org/package/transformers): `ReaderT`, `WriterT`, `StateT`, `ExceptT`.
- [`mtl` on Hackage](https://hackage.haskell.org/package/mtl): the typeclass layer (`MonadReader`, `MonadWriter`, `MonadState`, `MonadError`) that lets transformer stacks be used without manual `lift`s.
- [Martin Grabmüller, *Monad Transformers Step by Step*](https://page.mi.fu-berlin.de/scravy/realworldhaskell/materialien/monad-transformers-step-by-step.pdf): the classic worked-example tutorial building up a transformer stack piece by piece.

---

## Module

```swift
import CoreFP                 // TransformerStack, MonadT, inner-shape protocols, CoreFP-only stacks (OptionalTArray, PublisherTOptional, …)
import CoreFPOperators        // Operators for the CoreFP-only stacks
import DataStructure          // Stacks with a DataStructure layer (ReaderTEither, StatefulTWriter, …)
import DataStructureOperators // Operators for those stacks (<£>, <*>, >>-, >=>, …)
```
