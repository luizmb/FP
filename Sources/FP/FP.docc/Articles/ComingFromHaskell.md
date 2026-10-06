# Coming from Haskell

How Haskell's types, classes and operators map onto FP.

## Overview

FP follows Haskell's semantics (`base`, `transformers`, the streaming libraries): when Swift
ergonomics and Haskell's laws disagree, the laws win. `<*>` always equals `ap` for a monad, and a
transformer stack only gets a monad where `transformers` defines one. Names borrow from Scala Cats
where Haskell's would clash with Swift (`>>=` is a Swift operator, so bind is `>>-`; `State` clashes
with SwiftUI, so the state monad is `Stateful`).

Swift has no higher-kinded types, so `Functor`, `Applicative`, `Monad` and `Traversable` are not
protocols. Each type carries its own concrete `map` / `apply` / `flatMap` / `traverse`, with the same
names and shapes everywhere. Monad transformers are concrete generated structs (`ReaderTEither`,
`StatefulTOptional`, …), described in <doc:MonadTransformers>.

## Types and operators

| Haskell | This library | Notes |
|---|---|---|
| `Maybe a` | `Optional<A>` | Swift's built-in optional, extended with full Functor/Applicative/Monad |
| `Either a b` | `Either<A, B>` | Unconstrained sum type, no `Error` requirement on either side |
| `[a]` | `[A]` / `Array<A>` | Swift's built-in array — nondeterminism via `flatMap` |
| `IO a` | _not modelled_ | This library doesn't wrap side effects in a type; effects are pushed to the boundary instead |
| `Reader r a` | `Reader<Env, A>` | Dependency injection monad |
| `Writer w a` | `Writer<Log, A>` | Append-as-you-go monad, also a Comonad (the `Env` comonad `(a, w)`) |
| `State s a` | `Stateful<S, A>` | Named `Stateful` (not `State`) to avoid clashing with SwiftUI |
| `Semigroup` | `Semigroup` | Same name, same law |
| `Monoid` | `Monoid` | Same name, same law |
| `newtype` | `Newtype<Tag, RawValue>` | Phantom-tagged wrapper instead of a language keyword |
| `Gen a` (QuickCheck) | `Gen<R, A>` (`Stateful<R, A>`, `R: RandomNumberGenerator & Sendable`) | Composable random generator, run with an explicitly injected RNG: `gen.run(&rng)` |
| `ReaderT r m a` / `ExceptT e m a` / `MaybeT m a` / `WriterT w m a` / `StateT s m a` | `ReaderTArray`, `PublisherTEither`, `StatefulTOptional`, … | The generated structs (see [Stacking Effects](#stacking-effects-monad-transformers)): lift with `.readerT` / `.publisherT` / …, unwrap with `.rawValue`; escape hatches `mapReaderT` / `mapExceptT` / `mapMaybeT` / `mapWriterT` / `mapStateT` |
| `Validation e a` (validation package) | `Validation<E, A>` | Accumulating applicative, no monad |
| `These a b` | `These<A, B>` | Inclusive-or |
| `NonEmpty a` | `NonEmpty<A>` | Non-empty sequence |
| `RemoteData` (PureScript) | `Loading<Success, Failure>` | Async lifecycle with stale values |
| `fmap` / `<$>` | `<£>` | Functor map, function on the left (`<&>` is `Data.Functor.<&>`, container on the left) |
| `<$` / `$>` | `<£` / `£>` | Replace with a constant |
| `<*>` | `<*>` | Applicative apply — same symbol |
| `>>=` | `>>-` | Monadic bind (renamed — Swift reserves `>>=` for bit-shift-assign) |
| `=<<` | `-<<` | Monadic bind, function on the left |
| `>=>` | `>=>` | Kleisli composition — same symbol |
| `<|>` | `<|>` | Alternative / choice — same symbol |
| `<>` | `<>` | Semigroup append — same symbol |
| `$` | `<|` | Function application, function on the left |
| `&` | `|>` | Function application, value on the left |
| `.` | `<<<` | Composition, right to left (`>>>` is Haskell's `Control.Arrow` `>>>`, left to right) |

Pure helpers are curried where Haskell's are (`fmap`, `withDefault`, `foldLeft`), so they compose
point-free. See <doc:OperatorVocabulary> for every operator and its precedence.
