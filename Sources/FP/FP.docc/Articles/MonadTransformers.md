# Monad Transformers

A monad transformer stacks two effects into one type, so you can work with both at once —
for example a computation that can fail (`Either`) *and* produce multiple results (`Array`),
or one that needs an environment (`Reader`) *and* might be absent (`Optional`).

This library names every stack `OuterTInner`. `WriterTEither` means `Writer<W, Either<L, A>>`
— the outer type wraps the inner type, and the capital `T` reads as "transformed with" or,
if you like your Haskell, as the `T` suffix in `ReaderT`/`WriterT`/`StateT`. `EitherTResult`
means `Either<L, Result<A, E>>` — outer `Either`, inner `Result`.

```swift
import DataStructure

// WriterTEither = Writer<W, Either<L, A>>
let w: Writer<[String], Either<String, Int>> = Writer(.right(5), ["ok"])

// EitherTResult = Either<L, Result<A, E>>
let e: Either<String, Result<Int, MyError>> = .right(.success(42))
```

---

## Why every combination is hand-written

In Haskell, a monad transformer is generic: `ReaderT r m a` works for *any* inner monad `m`,
because `ReaderT` is parameterised over a type constructor (`m :: * -> *`) and Haskell's
higher-kinded types let `Monad m => Monad (ReaderT r m)` be derived once, for every `m`.

Swift has no higher-kinded types — you cannot write `protocol MonadTransformer { associatedtype Inner<A> }`
and have it mean anything. A generic parameter in Swift is always a concrete type, never
"a generic type applied to something else." So there is no way to express "`Writer<W, Inner<A>>` is
a `Monad` whenever `Inner` is a `Monad`" as a single piece of code. Every outer/inner pairing needs
its own concrete `mapT` / `applyXxx` + `liftA2Xxx` / `flatMapT` written by hand, one file per
Functor/Applicative/Monad instance. This is the same limitation that rules out a shared `Functor`/
`Monad` protocol for the base types (see the library's "Swift Limitations" notes) — it just shows up
again, multiplied, at the transformer level: instead of one `Monad` instance per type, you need one
per *pair* of types.

The naming convention (`OuterTInner`) and the three-function shape (`mapT`, `applyXxx`/`liftA2Xxx`,
`flatMapT`) exist precisely to make this combinatorial explosion navigable: once you know the
convention, `ReaderTValidation`, `StatefulTWriter`, `EitherTNonEmpty`, … are all discoverable by
name and all expose the same operations in the same shape.

---

## Module placement

A transformer's home module follows the same two-layer split as everything else in the library:

- If **either side** of the stack is a `DataStructure` type — `Either`, `Validation`, `Reader`,
  `Stateful`, `Writer`, or `NonEmpty` — the stack lives in `DataStructure` (named functions) /
  `DataStructureOperators` (operator sugar).
- If **both sides** are Swift built-ins or plain `CoreFP` types — `Array`, `Optional`, `Result`,
  `AsyncSequence`/`AsyncStream`, `Publisher` — the stack lives in `CoreFP` / `CoreFPOperators`.

Verified against the current source tree:

```
$ find Sources -iname "ArrayTOptional*"
Sources/CoreFP/Array/ArrayTOptional+Applicative.swift   # both sides built-in → CoreFP
Sources/CoreFP/Array/ArrayTOptional+Functor.swift
Sources/CoreFP/Array/ArrayTOptional+Monad.swift
...

$ find Sources -iname "EitherTStateful*"
Sources/DataStructure/Either/EitherTStateful+Applicative.swift   # Either + Stateful → DataStructure
Sources/DataStructure/Either/EitherTStateful+Functor.swift
```

---

## Transformer coverage matrix

Rebuilt directly from the current `Sources/` tree (not copied from the stale summary — several
combos below, notably the `NonEmpty` family, are more complete than that document reports).
**F** = Functor (`mapT`), **A** = Applicative (`applyXxx`/`liftA2Xxx`), **M** = Monad (`flatMapT`).

### CoreFP combinations (both sides built-in / CoreFP)

| Stack | F | A | M |
|---|---|---|---|
| `OptionalTArray` | Yes | Yes | Yes |
| `OptionalTResult` | Yes | Yes | Yes |
| `ArrayTOptional` | Yes | Yes | Yes |
| `ArrayTResult` | Yes | Yes | Yes |
| `AsyncSequenceTOptional` | Yes | Yes | Yes |
| `AsyncSequenceTArray` | Yes | Yes | No |
| `AsyncSequenceTResult` | Yes | Yes | Yes |
| `PublisherTOptional` | Yes | Yes | Yes |
| `PublisherTArray` | Yes | Yes | No |
| `PublisherTResult` | Yes | Yes | Yes |

`ArrayTArray`, `OptionalTOptional`, `ResultTArray`, and `ResultTOptional` also exist but only as
`Traversable` (`sequence`/`traverse`) — flattening nested containers rather than a full
Functor/Applicative/Monad transformer stack.

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
| `AsyncSequenceTEither` | Yes | Yes | Yes |
| `PublisherTEither` | Yes | Yes | Yes |
| `NonEmptyTEither` | Yes | Yes | Yes |

`ResultTEither` also exists but only as `Traversable`. `EitherTValidation` has no Monad — see
below.

### `Validation` combinations

Validation is an accumulating Applicative and, by design, **never** a Monad — see "Why some
combos lack a Monad" below. Every `Validation` combination therefore stops at F/A:

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

`ResultTValidation` also exists but only as `Traversable`.

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
| `ReaderTAsyncSequence` | Yes | Yes | Yes |
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
| `AsyncStreamTStateful` | Yes | — | No |

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
| `AsyncStreamTWriter` | Yes | — | Yes |

### `NonEmpty` combinations

| Stack | F | A | M |
|---|---|---|---|
| `NonEmptyTEither` | Yes | Yes | Yes |
| `NonEmptyTOptional` | Yes | Yes | Yes |
| `NonEmptyTResult` | Yes | Yes | Yes |
| `OptionalTNonEmpty` | Yes | Yes | Yes |

(The remaining `NonEmpty` combinations — `EitherTNonEmpty`, `ValidationTNonEmpty`, `ReaderTNonEmpty`,
`StatefulTNonEmpty`, `WriterTNonEmpty` — are listed under their respective outer type above; every
one of them now has an Applicative instance, closing a gap that existed when `IMPLEMENTATION_SUMMARY.md`
was last updated.)

---

## Why some combos lack a Monad

**`Validation` — no Monad, anywhere, by design.** `Validation<E, A>` doesn't have a `flatMap` at
all, on the base type or on any transformer stack. Its `Applicative` instance combines errors
from *both* sides via `Semigroup` when it can — the whole point of the type is to collect every
validation failure in one pass. A `flatMap` would have to pick a single branch to continue with
in the failure case, throwing away every error but the first, which defeats the purpose. So
`Validation` and every `ValidationT*` stack stop at Functor + Applicative.

**A list inside a non-commutative outer layer: no Monad (Haskell's `ListT` done wrong).**
`EitherTArray`, `EitherTNonEmpty`, `StatefulTArray`, `StatefulTNonEmpty`, `WriterTArray`,
`WriterTNonEmpty`, `PublisherTArray` and `AsyncSequenceTArray` (`M<[A]>` / `M<NonEmpty<A>>`) stop
at Functor + Applicative. Binding element by element runs the outer effect once per element, so
associativity only holds when that effect commutes. With a `Writer` log, `(m >>= f) >>= g` logs
`["m", "f1", "f2", "g10", "g20"]` while `m >>= (f >=> g)` logs `["m", "f1", "g10", "f2", "g20"]`.
Haskell's `transformers` deprecated (and later removed) `ListT` for exactly this reason.

**`Writer` outside another monad: no Monad (no distributive law).** `WriterTReader`,
`WriterTStateful`, `WriterTPublisher` and `WriterTAsyncStream` (`Writer<W, M<A>>`) stop at
Functor + Applicative. The log sits outside the effect, so a bind would have to know the
continuation's log before running `M`, which it can't (dropping that log instead breaks left
identity). Haskell's `WriterT` is `M<Writer<W, A>>` (the log
inside), which this library ships as `ArrayTWriter`, `OptionalTWriter`, `ResultTWriter`,
`EitherTWriter`, `ReaderTWriter`, `PublisherTWriter`, `StatefulTWriter`, …

**A monad outside `Stateful`: no Monad.** `ArrayTStateful`, `OptionalTStateful`,
`ResultTStateful`, `EitherTStateful`, `PublisherTStateful` and `AsyncStreamTStateful`
(`M<Stateful<S, A>>`) stop at Functor + Applicative (`AsyncStreamTStateful` at Functor). The
outer layer is decided before the state runs, so a continuation can never reach it (the best a
"bind" can do is `fmap(Stateful.flatMap)`). Haskell has no transformer of this shape; use
`Stateful<S, Optional|Either|Result|Writer>` (`MaybeT`/`ExceptT`/`WriterT` over `State`) instead.

**`Stateful` outside `Reader`/`Publisher`/`AsyncStream`: no Monad.** `StatefulTReader`,
`StatefulTPublisher` and `StatefulTAsyncStream` (`Stateful<S, M<A>>`) stop at Functor +
Applicative. `Stateful` runs with `inout S`, which can't be captured by the escaping `Reader`,
Combine or async closures a bind would need. Thread the state around the stream instead, or use
`Stateful<S, Result<A, E>>` / `Stateful<S, Either<L, A>>` where sequencing is needed.

---

## A worked example: `EitherTResult`

`Either<L, Result<A, E>>` models two independent error channels — for example a routing/left-right
outcome (`Either`) wrapping a Swift-idiomatic fallible operation (`Result`). Composing across both
layers uses the transformer functions directly, or the `<£^>`/`>>-`/`>=>` operators, which delegate
to them:

```swift
import DataStructure
import DataStructureOperators

enum MyError: Error { case negative }

let ok: Either<String, Result<Int, MyError>> = .right(.success(21))

// mapT — transform the innermost value, leaving both outer layers alone
mapTEitherResult({ $0 * 2 }, ok)              // .right(.success(42))
{ $0 * 2 } <£^> ok                             // same, via the transformer-specific operator

// flatMapT — chain a function that returns a full Either<L, Result<B, E>>
let validated = flatMapTEitherResult(ok) { n in
    n >= 0 ? .right(.success(n)) : .right(.failure(.negative))
}
// .right(.success(21))   — value unchanged since it was already non-negative

ok >>- { n in n >= 0 ? .right(.success(n)) : .right(.failure(.negative)) }
// same result via the operator

// kleisliT — compose two functions that each return Either<L, Result<_, E>>
let parse:  (String) -> Either<String, Result<Int, MyError>> =
    { s in Int(s).map { .right(.success($0)) } ?? .left("not a number") }
let double: (Int)    -> Either<String, Result<Int, MyError>> =
    { n in .right(.success(n * 2)) }

let pipeline = parse >=> double
pipeline("21")   // .right(.success(42))
pipeline("nope") // .left("not a number")
```

A `.left` short-circuits immediately (the outer `Either` layer), a `.right(.failure(_))`
short-circuits the inner `Result` while staying `.right` (see `flatMapTEitherResult`'s handling
of `.failure` above), and only `.right(.success(_))` continues the chain — exactly the semantics
you'd expect from stacking two short-circuiting monads.

---

## For Haskell developers

The concept maps directly onto `mtl`/`transformers`: `ReaderTReader`, `ReaderTResult`,
`WriterTEither`, `StatefulTEither`, and friends are this library's answer to `ReaderT`, `WriterT`,
`StateT`, and `ExceptT`. `mapT` is `fmap` lifted through the stack, `flatMapT` is `>>=` lifted
through the stack, and `kleisliT` is `>=>` lifted through the stack.

The difference is entirely mechanical, not conceptual: in Haskell, `ReaderT r m a` is `r ->
m a` for *any* monad `m`, and `Monad m => Monad (ReaderT r m)` is one instance declaration that
covers every possible `m` because `m` is a higher-kinded type parameter. Here, `ReaderTResult`,
`ReaderTEither`, `ReaderTWriter`, etc. are separate concrete types, each with its own hand-written
`flatMapT`, because Swift generics cannot abstract over "a type that itself takes a type parameter."
The coverage matrix above is the price of that gap — and also the reason it's organised so
mechanically: once you've read one `mapT`/`flatMapT` pair, you've effectively read the shape of
all of them.

For the Haskell side of this mapping, see:
- [`transformers` on Hackage](https://hackage.haskell.org/package/transformers) — `ReaderT`, `WriterT`, `StateT`, `ExceptT`.
- [`mtl` on Hackage](https://hackage.haskell.org/package/mtl) — the typeclass layer (`MonadReader`, `MonadWriter`, `MonadState`, `MonadError`) that lets transformer stacks be used without manual `lift`s.
- [Martin Grabmüller, *Monad Transformers Step by Step*](https://page.mi.fu-berlin.de/scravy/realworldhaskell/materialien/monad-transformers-step-by-step.pdf) — the classic worked-example tutorial building up a transformer stack piece by piece.

---

## Module

```swift
import DataStructure          // Transformer named functions (mapT, applyXxx, liftA2Xxx, flatMapT, kleisliT)
import DataStructureOperators // Transformer operators (<£^>, <&^>, <*>, >>-, >=>…)
import CoreFP                 // CoreFP-only combos (OptionalTArray, ArrayTResult, PublisherTOptional, …)
import CoreFPOperators        // Operator variants for the CoreFP-only combos
```
