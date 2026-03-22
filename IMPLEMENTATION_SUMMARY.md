# FP Library — Implementation Summary

> Last updated: 2026-03-22 | **1221 tests · 122 suites · all passing ✅**

---

## Module Architecture

The library is organised as a strict two-layer system.

| Layer | Module | Role |
|---|---|---|
| Core | `CoreFP` | Named free functions for Swift built-ins and concurrency types |
| Operators | `CoreFPOperators` | Operator sugar (`<£>`, `>>-`, …) delegating to `CoreFP` |
| Core | `DataStructure` | Named free functions for custom FP types |
| Operators | `DataStructureOperators` | Operator sugar delegating to `DataStructure` |
| Umbrella | `FP` | Re-exports all four modules |

**Rule:** Operators never contain logic — they always delegate to a named function in the corresponding core module. The sole exception is inverted-direction operators (e.g. `<£` vs `£>`) whose body is one call to the forward form.

**Transformer naming:** `OuterTInner` where the left word is the outer (wrapping) type and the right word is the inner. E.g. `WriterTEither` = `Writer<W, Either<L, A>>`.

**Module placement rule:**
- If either side of a transformer involves `Either`, `Validation`, `Reader`, `Stateful`, or `Writer` → `DataStructure` / `DataStructureOperators`.
- If both sides are Swift built-ins or `CoreFP` types (`Array`, `Optional`, `Result`, `DeferredTask`, `DeferredStream`, `AsyncStream`, `Publisher`) → `CoreFP` / `CoreFPOperators`.

---

## Operator Vocabulary

| Operator | Haskell | Meaning |
|---|---|---|
| `<£>` | `<$>` | Functor map |
| `£>` / `<£` | `$>` / `<$` | Replace with constant |
| `<&>` | `<&>` | Flipped functor map |
| `<£^>` / `<&^>` | — | Transformer-specific fmap (no base overload; avoids resolution failure with many `<£>` overloads) |
| `<*>` | `<*>` | Applicative apply |
| `*>` / `<*` | `*>` / `<*` | Sequence, discard one side |
| `>>-` | `>>=` | Monadic bind (renamed to avoid Swift's `>>=`) |
| `-<<` | `=<<` | Flipped bind |
| `>=>` / `<=<` | `>=>` / `<=<` | Kleisli composition |
| `<>` | `<>` | Semigroup append |
| `<|>` | `<|>` | Alternative |
| `++` | `++` | List concatenation |
| `>>>` / `<<<` / `•` | `>>>` / `<<<` / `.` | Function composition |
| `£` / `<\|` / `\|>` | `$` / `<\|` / `\|>` | Function application |
| `^` | `^` | Power |

---

## Operator Precedence

```
9   FunctionCompositionForward    >>>  <<<  •
8   PowerPrecedence               ^
7   MultiplicationPrecedence      *  /  %
6   ConcatPrecedence              <>
6   AdditionPrecedence            +  -
5   AppendToList                  ++
4   FunctorOps                    <£>  £>  <£  <*>  *>  <*  <£^>  <&^>   (left)
3   AlternativePrecedence         <|>
1   KleisliCompositionRight       >=>  <=<  -<<                            (right)
1   MonadBindLeft                 >>-  <&>  <&^>                           (left)
0   LowPrecedenceFunctionCall     £  <|  |>
```

---

## Types and Typeclass Coverage

### CoreFP types

| Type | Functor | Applicative | Monad | Alt | bimap | join | void | Foldable |
|---|---|---|---|---|---|---|---|---|
| `Array` | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ |
| `Optional` | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ |
| `Result` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `DeferredTask` | ✅ | ✅ | ✅ | — | — | ✅ | ✅ | — |
| `DeferredStream` | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ | — |
| `AsyncSequence` | ✅ | ✅ | ✅ | — | — | — | — | — |
| `Publisher` | ✅ | ✅ | ✅ | ✅ | — | — | — | — |
| `Function` (`(R)->A`) | ✅ | ✅ | ✅ | — | — | ✅ | — | — |

### DataStructure types

| Type | Functor | Applicative | Monad | Alt | bimap | dimap | join | void | Foldable |
|---|---|---|---|---|---|---|---|---|---|
| `Either<L,R>` | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ |
| `Validation<E,A>` | ✅ | ✅ | ✅¹ | ✅ | ✅ | — | — | ✅ | ✅ |
| `Reader<Env,A>` | ✅ | ✅ | ✅ | — | — | ✅² | ✅ | ✅ | — |
| `Stateful<S,A>` | ✅ | ✅ | ✅ | — | — | — | ✅ | ✅ | — |
| `Writer<W,A>` | ✅ | ✅ | ✅ | — | — | — | ✅ | ✅ | — |

¹ `Validation` has a minimal `flatMap` but accumulates errors in `apply` — it is primarily an Applicative.
² `Reader.dimap` is the Profunctor instance: contramap the environment, map the output. Also exposes `contramapEnvironment` as a curried free function. `Stateful` is not a Profunctor (its state parameter is invariant).

All `bimap`, `join`, `void`, `dimap`/`contramapEnvironment` are available both as instance methods and as curried static/top-level free functions for point-free use.

---

## Transformer Stacks

Naming: `OuterTInner`. Every stack exposes `mapT` (Functor), `applyXxx` + `liftA2Xxx` (Applicative), `flatMapT` (Monad) where applicable, plus full operator coverage.

### CoreFP transformer stacks

| Stack | Outer | Inner | F | A | M |
|---|---|---|---|---|---|
| `OptionalTArray` | `Optional` | `Array` | ✅ | ✅ | ✅ |
| `OptionalTResult` | `Optional` | `Result` | ✅ | ✅ | ✅ |
| `ArrayTOptional` | `Array` | `Optional` | ✅ | ✅ | ✅ |
| `ArrayTResult` | `Array` | `Result` | ✅ | ✅ | ✅ |
| `DeferredTaskTOptional` | `DeferredTask` | `Optional` | ✅ | ✅ | ✅ |
| `DeferredTaskTArray` | `DeferredTask` | `Array` | ✅ | ✅ | ✅ |
| `DeferredTaskTResult` | `DeferredTask` | `Result` | ✅ | ✅ | ✅ |
| `DeferredStreamTOptional` | `DeferredStream` | `Optional` | ✅ | ✅ | ✅ |
| `DeferredStreamTArray` | `DeferredStream` | `Array` | ✅ | ✅ | ✅ |
| `DeferredStreamTResult` | `DeferredStream` | `Result` | ✅ | ✅ | ✅ |
| `AsyncSequenceTOptional` | `AsyncSequence` | `Optional` | ✅ | ✅ | ✅ |
| `AsyncSequenceTArray` | `AsyncSequence` | `Array` | ✅ | ✅ | ✅ |
| `AsyncSequenceTResult` | `AsyncSequence` | `Result` | ✅ | ✅ | ✅ |
| `PublisherTOptional` | `Publisher` | `Optional` | ✅ | ✅ | ✅ |
| `PublisherTArray` | `Publisher` | `Array` | ✅ | ✅ | ✅ |
| `PublisherTResult` | `Publisher` | `Result` | ✅ | ✅ | ✅ |

### Either transformer stacks (DataStructure)

| Stack | F | A | M |
|---|---|---|---|
| `OptionalTEither` | ✅ | ✅ | ✅ |
| `ArrayTEither` | ✅ | ✅ | ✅ |
| `DeferredTaskTEither` | ✅ | ✅ | ✅ |
| `DeferredStreamTEither` | ✅ | ✅ | ✅ |
| `AsyncSequenceTEither` | ✅ | ✅ | ✅ |
| `PublisherTEither` | ✅ | ✅ | ✅ |
| `EitherTOptional` | ✅ | ✅ | ✅ |
| `EitherTArray` | ✅ | ✅ | ✅ |
| `EitherTResult` | ✅ | ✅ | ✅ |
| `EitherTValidation` | ✅ | ✅ | ✅ |
| `EitherTStateful` | ✅ | ✅ | ✅ |
| `EitherTWriter` | ✅ | ✅ | ✅ |

### Validation transformer stacks (DataStructure)

Validation is an accumulating Applicative. All `ValidationT*` stacks expose Functor + Applicative only (no Monad — `flatMap` would lose accumulated errors).

| Stack | F | A |
|---|---|---|
| `ValidationTArray` | ✅ | ✅ |
| `ValidationTOptional` | ✅ | ✅ |
| `ValidationTResult` | ✅ | ✅ |
| `ValidationTEither` | ✅ | ✅ |
| `ValidationTReader` | ✅ | ✅ |
| `ValidationTStateful` | ✅ | ✅ |
| `ValidationTWriter` | ✅ | ✅ |
| `DeferredTaskTValidation` | ✅ | ✅ |
| `DeferredStreamTValidation` | ✅ | ✅ |

### Reader transformer stacks (DataStructure)

| Stack | F | A | M |
|---|---|---|---|
| `ReaderTOptional` | ✅ | ✅ | ✅ |
| `ReaderTResult` | ✅ | ✅ | ✅ |
| `ReaderTArray` | ✅ | ✅ | ✅ |
| `ReaderTEither` | ✅ | ✅ | ✅ |
| `ReaderTValidation` | ✅ | ✅ | — |
| `ReaderTReader` | ✅ | ✅ | ✅ |
| `ReaderTStateful` | ✅ | ✅ | ✅ |
| `ReaderTWriter` | ✅ | ✅ | ✅ |
| `ReaderTDeferredTask` | ✅ | ✅ | ✅ |
| `ReaderTDeferredStream` | ✅ | ✅ | ✅ |
| `ReaderTAsyncSequence` | ✅ | ✅ | ✅ |
| `ReaderTPublisher` | ✅ | ✅ | ✅ |

### Stateful transformer stacks (DataStructure)

`StatefulTDeferredTask` and `StatefulTDeferredStream` have no Monad instance — `flatMapT` would require `inout S` to cross an `@escaping`/`@Sendable` boundary, which Swift prohibits. Applicative is fine because state is threaded synchronously to extract the lazy values before any async execution.

| Stack | F | A | M |
|---|---|---|---|
| `StatefulTOptional` | ✅ | ✅ | ✅ |
| `StatefulTResult` | ✅ | ✅ | ✅ |
| `StatefulTArray` | ✅ | ✅ | ✅ |
| `StatefulTEither` | ✅ | ✅ | ✅ |
| `StatefulTValidation` | ✅ | ✅ | — |
| `StatefulTReader` | ✅ | ✅ | — |
| `StatefulTWriter` | ✅ | ✅ | ✅ |
| `StatefulTDeferredTask` | ✅ | ✅ | — |
| `StatefulTDeferredStream` | ✅ | ✅ | — |
| `StatefulTAsyncStream` | ✅ | ✅ | — |
| `StatefulTPublisher` | ✅ | ✅ | — |
| `ArrayTStateful` | ✅ | ✅ | ✅ |
| `OptionalTStateful` | ✅ | ✅ | ✅ |
| `ResultTStateful` | ✅ | ✅ | ✅ |
| `PublisherTStateful` | ✅ | ✅ | — |

### Writer transformer stacks (DataStructure)

| Stack | F | A | M |
|---|---|---|---|
| `WriterTOptional` | ✅ | ✅ | ✅ |
| `WriterTResult` | ✅ | ✅ | ✅ |
| `WriterTArray` | ✅ | ✅ | ✅ |
| `WriterTEither` | ✅ | ✅ | ✅ |
| `WriterTValidation` | ✅ | ✅ | — |
| `WriterTReader` | ✅ | ✅ | ✅ |
| `WriterTStateful` | ✅ | ✅ | ✅ |
| `WriterTDeferredTask` | ✅ | ✅ | ✅ |
| `WriterTDeferredStream` | ✅ | ✅ | ✅ |
| `WriterTAsyncStream` | ✅ | ✅ | ✅ |
| `WriterTPublisher` | ✅ | ✅ | — |
| `ArrayTWriter` | ✅ | ✅ | ✅ |
| `OptionalTWriter` | ✅ | ✅ | ✅ |
| `ResultTWriter` | ✅ | ✅ | ✅ |
| `PublisherTWriter` | ✅ | ✅ | — |
| `AsyncStreamTWriter` | ✅ | — | ✅ |

---

## Additional Features

### Traversable

`sequence :: (Traversable t, Applicative f) => t (f a) -> f (t a)`

| Traversed (`t`) | Effect (`f`) | Free form |
|---|---|---|
| `Array` | `Optional` | `sequenceArrayOptional` / `traverseArrayOptional` |
| `Array` | `Result` | `sequenceArrayResult` / `traverseArrayResult` |
| `Array` | `Array` | `sequenceArrayArray` |
| `Optional` | `Optional` | `sequenceOptionalOptional` |
| `Optional` | `Result` | `sequenceOptionalResult` |
| `Optional` | `Array` | `sequenceOptionalArray` |

### Semigroup / Monoid

`<>` operator for: `Array`, `String`, `Optional`, `Result`, `Dictionary`, `Set`, numeric types, `Bool`. `Monoid` (identity + combine) is implemented as a protocol used by `Writer`.

### Alternative

`<|>` operator for: `Array`, `Optional`, `Result`, `Either`, `DeferredStream` (concatenation), `Validation` (first-success), `Publisher` (first-success via `.catch`).

### Traversable operators

`<$>` / `£>` operator traversal for `Array` and `Optional` via the `TraversableFree` pattern.

### Optics

`Prism` for `Either`, `Result`, `Optional`, `Validation`. No `Lens` or `Iso` yet.

### Foldable

| Type | `fold` | `foldLeft` | `foldRight` | `foldMap` | `toList` |
|---|---|---|---|---|---|
| `Array` | — | ✅ | ✅ | ✅ | — |
| `Optional` | ✅ | — | — | ✅ | ✅ |
| `Result` | via `bifoldMap` | — | — | ✅ | ✅ |
| `Either` | via `bifoldMap` | — | — | ✅ | ✅ |
| `Validation` | via `match` | — | — | ✅ | ✅ |

`foldLeft`/`foldRight`/`foldMap` on `Array` are curried statics for point-free use. `fold` on `Optional` is Haskell's `maybe` function. `foldMap` uses the `Monoid` identity for the empty/failure case. No symbolic operator (Foldable has none in Haskell).

### Bifunctor (`bimap`)

Free curried functions for `Either`, `Result`, `Validation`. No dedicated operator (no Haskell standard symbol).

### Profunctor (`dimap`)

`Reader` is a Profunctor. Free curried `dimap` and `contramapEnvironment` functions provided.
`Stateful` is **not** a Profunctor — its state type is invariant. Proper state-zooming requires a `Lens` (not yet implemented).

### `join` / `void` free functions

Top-level free functions (not just static methods) for all monadic types:
- `join` for `Array`, `Optional`, `Result`, `DeferredTask`, `DeferredStream`, `Either`, `Reader`, `Stateful`, `Writer`, `Function`
- `void` for all of the above plus `Validation`

### SumType protocol

`Either`, `Result`, and related types share `SumType2<A,B>`, providing `.a`, `.b`, `.isA`, `.isB`, `match()` for free.

### Platform bridges

- `Completion+Either`, `Completion+Result` — Combine completion → sum types
- `AsyncThrowingStream+Either`, `AsyncThrowingStream+Result` — async throwing streams → typed sum types

---

## Known Architectural Limits

| Situation | Reason |
|---|---|
| `StatefulTDeferredTask` / `StatefulTDeferredStream` / `StatefulTPublisher` / `StatefulTAsyncStream` have no Monad | `flatMapT` closure would need to capture `inout S` across `@escaping`/`@Sendable` — Swift prohibits this |
| `Stateful` is not a Profunctor | State type `S` is invariant (appears in both covariant and contravariant position); proper zooming requires a `Lens` |
| `ValidationT*` stacks have no Monad | Validation's error-accumulation semantics are incompatible with `flatMap`'s short-circuit requirement |
| `WriterTPublisher` / `PublisherTStateful` have no Monad | Publisher combinators don't compose cleanly with `inout`-threading state or log-accumulating flatMap |
| Many `<£>` / `>>-` overloads cause SourceKit false positives | SourceKit's type checker fails with 12+ overloads for the same operator; `swift build` and `swift test` always succeed. `<£^>` / `<&^>` dedicated transformer operators sidestep this for fmap. |

---

## Roadmap

### Near term

| Item | Notes |
|---|---|
| `Alternative` for `DeferredTask` | Race semantics: first-to-succeed; needs a structured-concurrency `race` primitive |
| `Traversable` for `Either`, `Validation`, `Writer` | Extend the existing traversal infrastructure to these types as the traversed structure |
| `Bifoldable` / `Bitraversable` | Natural extension of `bimap`/`bifoldMap` for `Either`, `Validation` |

### Medium term

| Item | Notes |
|---|---|
| `Comonad` (`extract`, `extend`/`coflatMap`, `duplicate`) | `Reader` and `Writer` are natural comonads |
| `Lens` + `Iso` | Enables `Stateful.zoom`, composable field access; `Prism` already exists |

### Longer term

| Item | Notes |
|---|---|
| MTL-style monad classes (`MonadReader`, `MonadWriter`, `MonadState`) | Lift `ask`/`tell`/`get` through transformer stacks; limited by Swift's lack of multi-param type classes |
| `MonadError` (`throwError`, `catchError`) | For `Either`, `Result`, `DeferredTask` |
| Free Monad | Separates program structure from interpretation; requires `Functor` protocol constraint |
| Comonad-based stream processing | Cellular automata, sliding-window transforms |

---

## Build & Test

```bash
swift build        # builds all 5 targets
swift test         # 1221 tests, 122 suites, all passing

# Run a specific suite
swift test --filter "WriterCoreTests"

# Run a specific test
swift test --filter "EitherFunctorTests/bimapCurried"
```

**Test targets:** `CoreFPTests`, `CoreFPOperatorsTests`, `DataStructureTests`, `DataStructureOperatorsTests`

---

## Stats

| Metric | Count |
|---|---|
| Source files | 617 |
| Test files | 127 |
| Tests passing | 1221 |
| Test suites | 122 |
| SPM targets | 5 (CoreFP, CoreFPOperators, DataStructure, DataStructureOperators, FP) |
