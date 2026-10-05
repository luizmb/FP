# Transformer stacks

A transformer stack lets you work on the value inside two layers of effect at once, `Reader<Env, Result<A, E>>` or `[A?]`, without unwrapping the outer layer by hand at every step. In FP 3.0 each stack is its own struct, named `OuterTInner` (Haskell's `newtype` per transformer). The full coverage matrix is in the DocC article `MonadTransformers`.

## Contents

- The model in one paragraph
- In, work, out
- Composing functions that return stacks
- The escape hatch
- Applicative-only stacks
- Which stacks exist
- Migrating from FP 2.x

## The model in one paragraph

`ReaderTResult<Env, E, A>` wraps a `Reader<Env, Result<A, E>>`; `ArrayTOptional<A>` wraps `[A?]`; `PublisherTOptional<Failure, A>` wraps `AnyPublisher<A?, Failure>`. A nested value on its own is just its outer type (a `Reader<Env, [A]>` is a `Reader`, and `<£>` on it maps the whole array). The stack behaviour exists only once you wrap it. Every stack has `rawValue`, `init(rawValue:)`, `init(_:)`, `map` / static `fmap`, static `pure` / `apply` / `liftA2`, `seqRight` / `seqLeft`, and on lawful monads `flatMap`, static `bind`, static `kleisli` / `kleisliBack`. The operators are the usual ones: `<£>`, `<&>`, `£>`, `<£`, `<*>`, `*>`, `<*`, and `>>-`, `-<<`, `>=>`, `<=<` on monads. There are no transformer-specific operators.

## In, work, out

```swift
import FP

// in: the lifting property is named after the OUTER type (.arrayT, .readerT, .optionalT, .resultT,
// .eitherT, .statefulT, .writerT, .publisherT, .asyncStreamT, .validationT, .nonEmptyT)
let maybeNumbers: [Int?] = [1, nil, 3]
let doubled: [Int?] = maybeNumbers.arrayT.map { $0 * 2 }.rawValue  // [2, nil, 6]

// the initializer works too, handy point-free
let viaInit: [Int?] = ({ $0 + 1 } <£> ArrayTOptional(maybeNumbers)).rawValue  // [2, nil, 4]

// £> replaces each inner value, not the whole array
let marked: [String?] = (maybeNumbers.arrayT £> "x").rawValue  // ["x", nil, "x"]
```

With a function-like outer layer (`Reader`, `Stateful`), `rawValue` is still the nested type, so you run it as usual:

```swift
struct Env: Sendable { let rates: [String: Double] }
enum RateError: Error, Sendable { case unknown(String) }

let rate: @Sendable (String) -> Reader<Env, Result<Double, RateError>> = { code in
    Reader { env in env.rates[code].map(Result.success) ?? .failure(.unknown(code)) }
}

let inverse: Reader<Env, Result<Double, RateError>> = rate("EUR").readerT.map { 1 / $0 }.rawValue
let eurInverse = inverse(Env(rates: ["EUR": 0.5]))  // .success(2.0)
```

## Composing functions that return stacks

`flatMap`, `>>-` and `>=>` on a stack take functions that return the **stack**, so the continuation can use both layers (read the environment and fail, for a `ReaderTResult`). Lift the nested value inside the function:

```swift
let convert: @Sendable (String, String) -> ReaderTResult<Env, RateError, Double> = { from, to in
    rate(from).readerT >>- { fromRate in
        rate(to).readerT.map { toRate in toRate / fromRate }
    }
}

let rateOf: @Sendable (String) -> ReaderTResult<Env, RateError, Double> = { rate($0).readerT }
let halve: @Sendable (Double) -> ReaderTResult<Env, RateError, Double> = { .pure($0 / 2) }
let halfRate = rateOf >=> halve

let crossRate = convert("EUR", "GBP").rawValue(Env(rates: ["EUR": 0.5, "GBP": 0.25]))  // .success(0.5)
```

The first `.failure` short-circuits everything after it, like `ExceptT` in Haskell.

## The escape hatch

`map` and `flatMap` only see the innermost value. To use the rest of the underlying API (Reader's `local`, Array's `filter`, Combine's `receive(on:)`), each stack has one function `(O) -> O2` named after Haskell's: by the outer layer for Reader / Stateful / streams (`mapReaderT`, `mapStateT`, `mapPublisherT`, `mapAsyncStreamT`), otherwise by the inner layer for Optional / Either / Result / Writer (`mapMaybeT`, `mapExceptT`, `mapWriterT`), otherwise by the outer layer (`mapArrayT`, `mapOptionalT`, `mapEitherT`, `mapResultT`, `mapNonEmptyT`, `mapValidationT`).

```swift
// ArrayTOptional (inner Optional): mapMaybeT gets the whole [A?]
let present: ArrayTOptional<Int> = maybeNumbers.arrayT.mapMaybeT { $0.filter { $0 != nil } }

// ReaderTResult (outer Reader): mapReaderT gets the whole Reader, so local() is reachable
let withFallbackRates: ReaderTResult<Env, RateError, Double> = rate("EUR").readerT.mapReaderT { reader in
    reader.local { env in env.rates.isEmpty ? Env(rates: ["EUR": 1]) : env }
}
```

## Applicative-only stacks

Some combinations have no lawful monad, and the library doesn't pretend: they only get `map`, `pure`, `apply` / `<*>`, `liftA2`, `*>`, `<*` (and conform to `TransformerStack` instead of `MonadT`). Any stack with `Validation` is one of them, which is exactly what you want, since `Validation` accumulates errors and a monad would have to stop at the first:

```swift
let field: @Sendable (String) -> Reader<Env, Validation<[String], Double>> = { code in
    Reader { env in env.rates[code].map(Validation.success) ?? .failure(["no rate for \(code)"]) }
}

let both: Reader<Env, Validation<[String], Double>> =
    ReaderTValidation<Env, [String], Double>.liftA2(+)(field("EUR").readerT, field("XYZ").readerT).rawValue
let errors = both(Env(rates: [:]))  // .failure(["no rate for EUR", "no rate for XYZ"])
```

Other applicative-only shapes: a list inside a non-commutative layer (`EitherTArray`, `StatefulTArray`, `WriterTArray`, `PublisherTArray`, …), `Writer` outside another monad (`WriterTReader`, `WriterTStateful`, …), a monad outside `Stateful` (`OptionalTStateful`, `ArrayTStateful`, …). `AsyncStreamTStateful` is functor only. If you need to chain on one of those, flip the layers (`ReaderTWriter` instead of `WriterTReader`) or go through the escape hatch.

## Which stacks exist

Monads (`MonadT`): ArrayTEither, ArrayTOptional, ArrayTResult, ArrayTWriter, AsyncStreamTEither, AsyncStreamTOptional, AsyncStreamTResult, AsyncStreamTWriter, EitherTOptional, EitherTResult, EitherTWriter, NonEmptyTEither, NonEmptyTOptional, NonEmptyTResult, OptionalTArray, OptionalTEither, OptionalTNonEmpty, OptionalTResult, OptionalTWriter, PublisherTEither, PublisherTOptional, PublisherTResult, PublisherTWriter, ReaderTArray, ReaderTAsyncStream, ReaderTEither, ReaderTNonEmpty, ReaderTOptional, ReaderTPublisher, ReaderTReader, ReaderTResult, ReaderTStateful, ReaderTWriter, ResultTWriter, StatefulTEither, StatefulTOptional, StatefulTResult, StatefulTWriter, WriterTEither, WriterTOptional, WriterTResult.

Applicative only (`TransformerStack`): ArrayTStateful, AsyncStreamTArray, EitherTArray, EitherTNonEmpty, EitherTStateful, EitherTValidation, OptionalTStateful, PublisherTArray, PublisherTStateful, ReaderTValidation, ResultTStateful, StatefulTArray, StatefulTAsyncStream, StatefulTNonEmpty, StatefulTPublisher, StatefulTReader, StatefulTValidation, ValidationTArray, ValidationTEither, ValidationTNonEmpty, ValidationTOptional, ValidationTReader, ValidationTResult, ValidationTStateful, ValidationTWriter, WriterTArray, WriterTAsyncStream, WriterTNonEmpty, WriterTPublisher, WriterTReader, WriterTStateful, WriterTValidation.

Functor only: AsyncStreamTStateful.

Stream stacks (`Publisher`, `AsyncStream`) bind with ordered concat (each inner stream runs to completion, in order) and their applicative is derived from that bind (cartesian, like the list applicative), never `zip`. Use `zip` explicitly when you want pairs.

## Migrating from FP 2.x

| 2.x | 3.0 |
|---|---|
| `x.mapT(f)`, `f <£^> x`, `x <&^> f`, `mapTEitherArray(f, x)` | `x.eitherT.map(f).rawValue`, or `(f <£> x.eitherT).rawValue` |
| `Either<L, [A]>.fmapT(f)` | `EitherTArray<L, A>.fmap(f)` (works on the stack) |
| `x.flatMapT(f)`, `x >>- f` on a nested value | `x.publisherT.flatMap(f)` / `x.publisherT >>- f`, with `f` returning the stack |
| `bindT(f)`, `kleisliT(f, g)`, `f >=> g` over nested-returning functions | `Stack.bind(f)`, `Stack.kleisli(f, g)`, `f >=> g` with `f` / `g` returning the stack |
| `applyReaderEither(ff, fa)`, `ff <*> fa` on nested values | `ReaderTEither.apply(ff.readerT, fa.readerT)` / `ff.readerT <*> fa.readerT` |
| `liftA2ReaderEither(f)(a, b)` | `ReaderTEither<Env, L, C>.liftA2(f)(a.readerT, b.readerT)` |
| `a *> b` on nested values | `a.statefulT *> b.statefulT` |
| reaching the outer type (`r.mapReader { … }`) | `stack.mapReaderT { … }` |
| `AsyncSequenceT…`, `ReaderTAsyncSequence` | `AsyncStreamT…`, `ReaderTAsyncStream` |

Careful when upgrading: the operator overloads on nested shapes are gone, and since a nested value is now just its outer type, some old call sites still compile with a different meaning instead of failing. `*>` on a `Stateful<S, Either<L, A>>` now resolves to `Stateful`'s `*>` (it no longer skips the right side on `.left`), and `<£>` / `>>-` on a `Reader<E, [A]>` act on the whole array. Search for operators applied to nested values and wrap them in their stack, rather than trusting the compiler to flag them.
