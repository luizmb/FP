# ``DataStructureOperators``

The operator syntax for everything in `DataStructure` — Functor/Applicative/Monad operators for `Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, `NonEmpty`, `These`, `Zipper`, plus every `OuterTInner` transformer combo between them.

## Overview

Every operator here delegates to a named function in [DataStructure](../datastructure) — the operator module never implements logic itself, only syntax. Import both modules together (or the [FP](../fp) umbrella, which re-exports everything):

```swift
import DataStructure
import DataStructureOperators

let parsed = Either<String, Int>.right(5) >>- { n in n > 0 ? .right(n) : .left("negative") }
```

The full, verified operator/precedence table across both `CoreFPOperators` and `DataStructureOperators` lives in [OperatorVocabulary](../fp/operatorvocabulary).

Every operator here is heavily overloaded — one per type it applies to (`Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, `NonEmpty`, `These`, `Zipper`, and every transformer combo between them). Grouped below by mathematical concept, then by type.

## Related Modules

| Module | Contents |
|--------|----------|
| [FP (umbrella)](../fp) | Re-exports all four modules; also the home of cross-cutting conceptual articles |
| [CoreFP](../corefp) | Optics, Semigroup/Monoid, standard-library extensions |
| [CoreFPOperators](../corefpoperators) | Operator syntax for `CoreFP` |
| [DataStructure](../datastructure) | Named functions this module's operators delegate to |

## Topics

### Functor — `<£>` / `<&>` (fn-left / container-left)

**Either**
- ``<£>(_:_:)->Either<A,B1>``
- ``<&>(_:_:)->Either<A,B1>``

**Validation**
- ``<£>(_:_:)->Validation<E,B>``
- ``<&>(_:_:)->Validation<E,B>``

**These**
- ``<£>(_:_:)->These<A,B1>``
- ``<&>(_:_:)->These<A,C>``

**Reader**
- ``<£>(_:_:)->Reader<Env,B>``
- ``<&>(_:_:)->Reader<Env,O1>``

**Writer**
- ``<£>(_:_:)->Writer<W,B>``
- ``<&>(_:_:)->Writer<W,B>``

**Stateful**
- ``<£>(_:_:)->Stateful<S,B>``
- ``<&>(_:_:)->Stateful<S,B>``

**Loading**
- ``<£>(_:_:)->Loading<B,F>``
- ``<&>(_:_:)->Loading<B,F>``

**NonEmpty**
- ``<£>(_:_:)->NonEmpty<B>``
- ``<&>(_:_:)->NonEmpty<B>``

**Zipper**
- ``<£>(_:_:)->Zipper<B>``
- ``<&>(_:_:)->Zipper<B>``

**Transformer (nested) functor map — `<£^>` / `<&^>`**

*Either*
- ``<£^>(_:_:)->Either<L,B>?``
- ``<£^>(_:_:)->Either<L,B?>``
- ``<£^>(_:_:)->Either<L,NonEmpty<B>>``
- ``<£^>(_:_:)->Either<L,Result<B,E>>``
- ``<£^>(_:_:)->Either<L,Stateful<S,B>>``
- ``<£^>(_:_:)->Either<L,Validation<E,B>>``
- ``<£^>(_:_:)->Either<L,Writer<W,B>>``
- ``<£^>(_:_:)->Either<L,[B]>``
- ``<£^>(_:_:)->[Either<L,B>]``
- ``<&^>(_:_:)->Either<L,B>?``
- ``<&^>(_:_:)->Either<L,B?>``
- ``<&^>(_:_:)->Either<L,NonEmpty<B>>``
- ``<&^>(_:_:)->Either<L,Result<B,E>>``
- ``<&^>(_:_:)->Either<L,Stateful<S,B>>``
- ``<&^>(_:_:)->Either<L,Validation<E,B>>``
- ``<&^>(_:_:)->Either<L,Writer<W,B>>``
- ``<&^>(_:_:)->Either<L,[B]>``
- ``<&^>(_:_:)->[Either<L,B>]``

*Validation*
- ``<£^>(_:_:)->Validation<E,B?>``
- ``<£^>(_:_:)->Validation<E,Either<L,B>>``
- ``<£^>(_:_:)->Validation<E,NonEmpty<B>>``
- ``<£^>(_:_:)->Validation<E,Reader<Env,B>>``
- ``<£^>(_:_:)->Validation<E,Result<B,Err>>``
- ``<£^>(_:_:)->Validation<E,Stateful<S,B>>``
- ``<£^>(_:_:)->Validation<E,Writer<W,B>>``
- ``<£^>(_:_:)->Validation<E,[B]>``
- ``<&^>(_:_:)->Validation<E,B?>``
- ``<&^>(_:_:)->Validation<E,Either<L,B>>``
- ``<&^>(_:_:)->Validation<E,NonEmpty<B>>``
- ``<&^>(_:_:)->Validation<E,Reader<Env,B>>``
- ``<&^>(_:_:)->Validation<E,Result<B,Err>>``
- ``<&^>(_:_:)->Validation<E,Stateful<S,B>>``
- ``<&^>(_:_:)->Validation<E,Writer<W,B>>``
- ``<&^>(_:_:)->Validation<E,[B]>``

*Reader*
- ``<£^>(_:_:)->Reader<Env,AsyncMapSequence<AsyncStream<A>,B>>``
- ``<£^>(_:_:)->Reader<Env,B?>``
- ``<£^>(_:_:)->Reader<Env,Either<L,B>>``
- ``<£^>(_:_:)->Reader<Env,NonEmpty<B>>``
- ``<£^>(_:_:)->Reader<Env,Publisher<B,E>>``
- ``<£^>(_:_:)->Reader<Env,Result<B,E>>``
- ``<£^>(_:_:)->Reader<Env,Stateful<S,B>>``
- ``<£^>(_:_:)->Reader<Env,Validation<E,B>>``
- ``<£^>(_:_:)->Reader<Env,Writer<W,B>>``
- ``<£^>(_:_:)->Reader<Env,[B]>``
- ``<£^>(_:_:)->Reader<Env1,Reader<Env2,B>>``
- ``<&^>(_:_:)->Reader<Env,AsyncMapSequence<AsyncStream<A>,B>>``
- ``<&^>(_:_:)->Reader<Env,B?>``
- ``<&^>(_:_:)->Reader<Env,Either<L,B>>``
- ``<&^>(_:_:)->Reader<Env,NonEmpty<B>>``
- ``<&^>(_:_:)->Reader<Env,Publisher<B,E>>``
- ``<&^>(_:_:)->Reader<Env,Result<B,E>>``
- ``<&^>(_:_:)->Reader<Env,Stateful<S,B>>``
- ``<&^>(_:_:)->Reader<Env,Validation<E,B>>``
- ``<&^>(_:_:)->Reader<Env,Writer<W,B>>``
- ``<&^>(_:_:)->Reader<Env,[B]>``
- ``<&^>(_:_:)->Reader<Env1,Reader<Env2,B>>``

*Writer*
- ``<£^>(_:_:)->Writer<W,AsyncMapSequence<AsyncStream<A>,B>>``
- ``<£^>(_:_:)->Writer<W,B>?``
- ``<£^>(_:_:)->Writer<W,B?>``
- ``<£^>(_:_:)->Writer<W,Either<L,B>>``
- ``<£^>(_:_:)->Writer<W,NonEmpty<B>>``
- ``<£^>(_:_:)->Writer<W,Publisher<B,E>>``
- ``<£^>(_:_:)->Writer<W,Reader<Env,B>>``
- ``<£^>(_:_:)->Writer<W,Result<B,E>>``
- ``<£^>(_:_:)->Writer<W,Stateful<S,B>>``
- ``<£^>(_:_:)->Writer<W,Validation<E,B>>``
- ``<£^>(_:_:)->Writer<W,[B]>``
- ``<£^>(_:_:)->[Writer<W,B>]``
- ``<&^>(_:_:)->Writer<W,AsyncMapSequence<AsyncStream<A>,B>>``
- ``<&^>(_:_:)->Writer<W,B>?``
- ``<&^>(_:_:)->Writer<W,B?>``
- ``<&^>(_:_:)->Writer<W,Either<L,B>>``
- ``<&^>(_:_:)->Writer<W,NonEmpty<B>>``
- ``<&^>(_:_:)->Writer<W,Publisher<B,E>>``
- ``<&^>(_:_:)->Writer<W,Reader<Env,B>>``
- ``<&^>(_:_:)->Writer<W,Result<B,E>>``
- ``<&^>(_:_:)->Writer<W,Stateful<S,B>>``
- ``<&^>(_:_:)->Writer<W,Validation<E,B>>``
- ``<&^>(_:_:)->Writer<W,[B]>``
- ``<&^>(_:_:)->[Writer<W,B>]``

*Stateful*
- ``<£^>(_:_:)->Stateful<S,AsyncMapSequence<AsyncStream<A>,B>>``
- ``<£^>(_:_:)->Stateful<S,B>?``
- ``<£^>(_:_:)->Stateful<S,B?>``
- ``<£^>(_:_:)->Stateful<S,Either<L,B>>``
- ``<£^>(_:_:)->Stateful<S,NonEmpty<B>>``
- ``<£^>(_:_:)->Stateful<S,Publisher<B,E>>``
- ``<£^>(_:_:)->Stateful<S,Reader<Env,B>>``
- ``<£^>(_:_:)->Stateful<S,Result<B,E>>``
- ``<£^>(_:_:)->Stateful<S,Validation<E,B>>``
- ``<£^>(_:_:)->Stateful<S,Writer<W,B>>``
- ``<£^>(_:_:)->Stateful<S,[B]>``
- ``<£^>(_:_:)->[Stateful<S,B>]``
- ``<&^>(_:_:)->Stateful<S,AsyncMapSequence<AsyncStream<A>,B>>``
- ``<&^>(_:_:)->Stateful<S,B>?``
- ``<&^>(_:_:)->Stateful<S,B?>``
- ``<&^>(_:_:)->Stateful<S,Either<L,B>>``
- ``<&^>(_:_:)->Stateful<S,NonEmpty<B>>``
- ``<&^>(_:_:)->Stateful<S,Publisher<B,E>>``
- ``<&^>(_:_:)->Stateful<S,Reader<Env,B>>``
- ``<&^>(_:_:)->Stateful<S,Result<B,E>>``
- ``<&^>(_:_:)->Stateful<S,Validation<E,B>>``
- ``<&^>(_:_:)->Stateful<S,Writer<W,B>>``
- ``<&^>(_:_:)->Stateful<S,[B]>``
- ``<&^>(_:_:)->[Stateful<S,B>]``

*NonEmpty*
- ``<£^>(_:_:)->NonEmpty<B>?``
- ``<£^>(_:_:)->NonEmpty<B?>``
- ``<£^>(_:_:)->NonEmpty<Either<L,B>>``
- ``<£^>(_:_:)->NonEmpty<Result<B,E>>``
- ``<&^>(_:_:)->NonEmpty<B>?``
- ``<&^>(_:_:)->NonEmpty<B?>``
- ``<&^>(_:_:)->NonEmpty<Either<L,B>>``
- ``<&^>(_:_:)->NonEmpty<Result<B,E>>``

*Result*
- ``<£^>(_:_:)->Result<Stateful<S,B>,E>``
- ``<£^>(_:_:)->Result<Writer<W,B>,E>``
- ``<&^>(_:_:)->Result<Stateful<S,B>,E>``
- ``<&^>(_:_:)->Result<Writer<W,B>,E>``

*Publisher*
- ``<£^>(_:_:)->AnyPublisher<Either<L,B>,E>``
- ``<£^>(_:_:)->AnyPublisher<Stateful<S,B>,E>``
- ``<£^>(_:_:)->AnyPublisher<Writer<W,B>,E>``
- ``<&^>(_:_:)->AnyPublisher<Either<L,B>,E>``
- ``<&^>(_:_:)->AnyPublisher<Stateful<S,B>,E>``
- ``<&^>(_:_:)->AnyPublisher<Writer<W,B>,E>``

*AsyncSequence*
- ``<£^>(_:_:)->AsyncMapSequence<AsyncStream<Stateful<S,A>>,Stateful<S,B>>``
- ``<£^>(_:_:)->AsyncMapSequence<AsyncStream<Writer<W,A>>,Writer<W,B>>``
- ``<£^>(_:_:)->AsyncStream<Either<L,B>>``
- ``<&^>(_:_:)->AsyncMapSequence<AsyncStream<Stateful<S,A>>,Stateful<S,B>>``
- ``<&^>(_:_:)->AsyncMapSequence<AsyncStream<Writer<W,A>>,Writer<W,B>>``
- ``<&^>(_:_:)->AsyncStream<Either<L,B>>``

### Applicative — `<*>` (apply), `*>` / `<*` (sequence)

**Either**
- ``<*>(_:_:)->Either<A,B>``
- ``<*>(_:_:)->Either<L,B>?``
- ``<*>(_:_:)->Either<L,B?>``
- ``<*>(_:_:)->Either<L,NonEmpty<B>>``
- ``<*>(_:_:)->Either<L,Result<B,E>>``
- ``<*>(_:_:)->Either<L,Stateful<S,B>>``
- ``<*>(_:_:)->Either<L,Validation<E,B>>``
- ``<*>(_:_:)->Either<L,Writer<W,B>>``
- ``<*>(_:_:)->Either<L,[B]>``
- ``<*>(_:_:)->[Either<L,B>]``
- ``*>(_:_:)->Either<A,B>``
- ``*>(_:_:)->Either<L,B>?``
- ``*>(_:_:)->Either<L,B?>``
- ``*>(_:_:)->Either<L,NonEmpty<B>>``
- ``*>(_:_:)->Either<L,Result<B,E>>``
- ``*>(_:_:)->Either<L,Stateful<S,B>>``
- ``*>(_:_:)->Either<L,Validation<E,B>>``
- ``*>(_:_:)->Either<L,Writer<W,B>>``
- ``*>(_:_:)->Either<L,[B]>``
- ``*>(_:_:)->[Either<L,B>]``
- ``<*(_:_:)->Either<A,B>``
- ``<*(_:_:)->Either<L,A>?``
- ``<*(_:_:)->Either<L,A?>``
- ``<*(_:_:)->Either<L,NonEmpty<A>>``
- ``<*(_:_:)->Either<L,Result<A,E>>``
- ``<*(_:_:)->Either<L,Stateful<S,A>>``
- ``<*(_:_:)->Either<L,Validation<E,A>>``
- ``<*(_:_:)->Either<L,Writer<W,A>>``
- ``<*(_:_:)->Either<L,[A]>``
- ``<*(_:_:)->[Either<L,A>]``

**Validation**
- ``<*>(_:_:)->Validation<E,B>``
- ``<*>(_:_:)->Validation<E,B?>``
- ``<*>(_:_:)->Validation<E,Either<L,B>>``
- ``<*>(_:_:)->Validation<E,NonEmpty<B>>``
- ``<*>(_:_:)->Validation<E,Reader<Env,B>>``
- ``<*>(_:_:)->Validation<E,Result<B,Err>>``
- ``<*>(_:_:)->Validation<E,Stateful<S,B>>``
- ``<*>(_:_:)->Validation<E,Writer<W,B>>``
- ``<*>(_:_:)->Validation<E,[B]>``
- ``*>(_:_:)->Validation<E,B>``
- ``*>(_:_:)->Validation<E,B?>``
- ``*>(_:_:)->Validation<E,Either<L,B>>``
- ``*>(_:_:)->Validation<E,NonEmpty<B>>``
- ``*>(_:_:)->Validation<E,Reader<Env,B>>``
- ``*>(_:_:)->Validation<E,Result<B,Err>>``
- ``*>(_:_:)->Validation<E,Stateful<S,B>>``
- ``*>(_:_:)->Validation<E,Writer<W,B>>``
- ``*>(_:_:)->Validation<E,[B]>``
- ``<*(_:_:)->Validation<E,A>``
- ``<*(_:_:)->Validation<E,A?>``
- ``<*(_:_:)->Validation<E,Either<L,A>>``
- ``<*(_:_:)->Validation<E,NonEmpty<A>>``
- ``<*(_:_:)->Validation<E,Reader<Env,A>>``
- ``<*(_:_:)->Validation<E,Result<A,Err>>``
- ``<*(_:_:)->Validation<E,Stateful<S,A>>``
- ``<*(_:_:)->Validation<E,Writer<W,A>>``
- ``<*(_:_:)->Validation<E,[A]>``

**These**
- ``<*>(_:_:)->These<A,C>``
- ``*>(_:_:)->These<A,B>``
- ``<*(_:_:)->These<A,B>``

**Reader**
- ``<*>(_:_:)->Reader<Env,B>``
- ``<*>(_:_:)->Reader<Env,B?>``
- ``<*>(_:_:)->Reader<Env,Either<L,B>>``
- ``<*>(_:_:)->Reader<Env,NonEmpty<B>>``
- ``<*>(_:_:)->Reader<Env,Publisher<B,E>>``
- ``<*>(_:_:)->Reader<Env,Result<B,E>>``
- ``<*>(_:_:)->Reader<Env,Stateful<S,B>>``
- ``<*>(_:_:)->Reader<Env,Validation<E,B>>``
- ``<*>(_:_:)->Reader<Env,Writer<W,B>>``
- ``<*>(_:_:)->Reader<Env,[B]>``
- ``<*>(_:_:)->Reader<Env1,Reader<Env2,B>>``
- ``*>(_:_:)->Reader<Env,AsyncMapSequence<AsyncStream<(A,B)>,B>>``
- ``*>(_:_:)->Reader<Env,B>``
- ``*>(_:_:)->Reader<Env,B?>``
- ``*>(_:_:)->Reader<Env,Either<L,B>>``
- ``*>(_:_:)->Reader<Env,NonEmpty<B>>``
- ``*>(_:_:)->Reader<Env,Publisher<B,E>>``
- ``*>(_:_:)->Reader<Env,Result<B,E>>``
- ``*>(_:_:)->Reader<Env,Stateful<S,B>>``
- ``*>(_:_:)->Reader<Env,Validation<E,B>>``
- ``*>(_:_:)->Reader<Env,Writer<W,B>>``
- ``*>(_:_:)->Reader<Env,[B]>``
- ``*>(_:_:)->Reader<Env1,Reader<Env2,B>>``
- ``<*(_:_:)->Reader<Env,A>``
- ``<*(_:_:)->Reader<Env,A?>``
- ``<*(_:_:)->Reader<Env,AsyncMapSequence<AsyncStream<(A,B)>,A>>``
- ``<*(_:_:)->Reader<Env,Either<L,A>>``
- ``<*(_:_:)->Reader<Env,NonEmpty<A>>``
- ``<*(_:_:)->Reader<Env,Publisher<A,E>>``
- ``<*(_:_:)->Reader<Env,Result<A,E>>``
- ``<*(_:_:)->Reader<Env,Stateful<S,A>>``
- ``<*(_:_:)->Reader<Env,Validation<E,A>>``
- ``<*(_:_:)->Reader<Env,Writer<W,A>>``
- ``<*(_:_:)->Reader<Env,[A]>``
- ``<*(_:_:)->Reader<Env1,Reader<Env2,A>>``

**Writer**
- ``<*>(_:_:)->Writer<W,B>?``
- ``<*>(_:_:)->Writer<W,B>``
- ``<*>(_:_:)->Writer<W,B?>``
- ``<*>(_:_:)->Writer<W,Either<L,B>>``
- ``<*>(_:_:)->Writer<W,NonEmpty<B>>``
- ``<*>(_:_:)->Writer<W,Publisher<B,E>>``
- ``<*>(_:_:)->Writer<W,Reader<Env,B>>``
- ``<*>(_:_:)->Writer<W,Result<B,E>>``
- ``<*>(_:_:)->Writer<W,Stateful<S,B>>``
- ``<*>(_:_:)->Writer<W,Validation<E,B>>``
- ``<*>(_:_:)->Writer<W,[B]>``
- ``<*>(_:_:)->[Writer<W,B>]``
- ``*>(_:_:)->Writer<W,AsyncMapSequence<AsyncStream<(A,B)>,B>>``
- ``*>(_:_:)->Writer<W,B>?``
- ``*>(_:_:)->Writer<W,B>``
- ``*>(_:_:)->Writer<W,B?>``
- ``*>(_:_:)->Writer<W,Either<L,B>>``
- ``*>(_:_:)->Writer<W,NonEmpty<B>>``
- ``*>(_:_:)->Writer<W,Publisher<B,E>>``
- ``*>(_:_:)->Writer<W,Reader<Env,B>>``
- ``*>(_:_:)->Writer<W,Result<B,E>>``
- ``*>(_:_:)->Writer<W,Stateful<S,B>>``
- ``*>(_:_:)->Writer<W,Validation<E,B>>``
- ``*>(_:_:)->Writer<W,[B]>``
- ``*>(_:_:)->[Writer<W,B>]``
- ``<*(_:_:)->Writer<W,A>?``
- ``<*(_:_:)->Writer<W,A>``
- ``<*(_:_:)->Writer<W,A?>``
- ``<*(_:_:)->Writer<W,AsyncMapSequence<AsyncStream<(A,B)>,A>>``
- ``<*(_:_:)->Writer<W,Either<L,A>>``
- ``<*(_:_:)->Writer<W,NonEmpty<A>>``
- ``<*(_:_:)->Writer<W,Publisher<A,E>>``
- ``<*(_:_:)->Writer<W,Reader<Env,A>>``
- ``<*(_:_:)->Writer<W,Result<A,E>>``
- ``<*(_:_:)->Writer<W,Stateful<S,A>>``
- ``<*(_:_:)->Writer<W,Validation<E,A>>``
- ``<*(_:_:)->Writer<W,[A]>``
- ``<*(_:_:)->[Writer<W,A>]``

**Stateful**
- ``<*>(_:_:)->Stateful<S,B>?``
- ``<*>(_:_:)->Stateful<S,B>``
- ``<*>(_:_:)->Stateful<S,B?>``
- ``<*>(_:_:)->Stateful<S,Either<L,B>>``
- ``<*>(_:_:)->Stateful<S,NonEmpty<B>>``
- ``<*>(_:_:)->Stateful<S,Publisher<B,E>>``
- ``<*>(_:_:)->Stateful<S,Reader<Env,B>>``
- ``<*>(_:_:)->Stateful<S,Result<B,E>>``
- ``<*>(_:_:)->Stateful<S,Validation<E,B>>``
- ``<*>(_:_:)->Stateful<S,Writer<W,B>>``
- ``<*>(_:_:)->Stateful<S,[B]>``
- ``<*>(_:_:)->[Stateful<S,B>]``
- ``*>(_:_:)->Stateful<S,AsyncMapSequence<AsyncStream<(A,B)>,B>>``
- ``*>(_:_:)->Stateful<S,B>?``
- ``*>(_:_:)->Stateful<S,B>``
- ``*>(_:_:)->Stateful<S,B?>``
- ``*>(_:_:)->Stateful<S,Either<L,B>>``
- ``*>(_:_:)->Stateful<S,NonEmpty<B>>``
- ``*>(_:_:)->Stateful<S,Publisher<B,E>>``
- ``*>(_:_:)->Stateful<S,Reader<Env,B>>``
- ``*>(_:_:)->Stateful<S,Result<B,E>>``
- ``*>(_:_:)->Stateful<S,Validation<E,B>>``
- ``*>(_:_:)->Stateful<S,Writer<W,B>>``
- ``*>(_:_:)->Stateful<S,[B]>``
- ``*>(_:_:)->[Stateful<S,B>]``
- ``<*(_:_:)->Stateful<S,A>?``
- ``<*(_:_:)->Stateful<S,A>``
- ``<*(_:_:)->Stateful<S,A?>``
- ``<*(_:_:)->Stateful<S,AsyncMapSequence<AsyncStream<(A,B)>,A>>``
- ``<*(_:_:)->Stateful<S,Either<L,A>>``
- ``<*(_:_:)->Stateful<S,NonEmpty<A>>``
- ``<*(_:_:)->Stateful<S,Publisher<A,E>>``
- ``<*(_:_:)->Stateful<S,Reader<Env,A>>``
- ``<*(_:_:)->Stateful<S,Result<A,E>>``
- ``<*(_:_:)->Stateful<S,Validation<E,A>>``
- ``<*(_:_:)->Stateful<S,Writer<W,A>>``
- ``<*(_:_:)->Stateful<S,[A]>``
- ``<*(_:_:)->[Stateful<S,A>]``

**Loading**
- ``<*>(_:_:)->Loading<S,F>``
- ``*>(_:_:)->Loading<S,F>``
- ``<*(_:_:)->Loading<S,F>``

**NonEmpty**
- ``<*>(_:_:)->NonEmpty<B>?``
- ``<*>(_:_:)->NonEmpty<B>``
- ``<*>(_:_:)->NonEmpty<B?>``
- ``<*>(_:_:)->NonEmpty<Either<L,B>>``
- ``<*>(_:_:)->NonEmpty<Result<B,E>>``
- ``*>(_:_:)->NonEmpty<B>?``
- ``*>(_:_:)->NonEmpty<B>``
- ``*>(_:_:)->NonEmpty<B?>``
- ``*>(_:_:)->NonEmpty<Either<L,B>>``
- ``*>(_:_:)->NonEmpty<Result<B,E>>``
- ``<*(_:_:)->NonEmpty<A>?``
- ``<*(_:_:)->NonEmpty<A>``
- ``<*(_:_:)->NonEmpty<A?>``
- ``<*(_:_:)->NonEmpty<Either<L,A>>``
- ``<*(_:_:)->NonEmpty<Result<A,E>>``

**Result**
- ``<*>(_:_:)->Result<Stateful<S,B>,E>``
- ``<*>(_:_:)->Result<Writer<W,B>,E>``
- ``*>(_:_:)->Result<Stateful<S,B>,E>``
- ``*>(_:_:)->Result<Writer<W,B>,E>``
- ``<*(_:_:)->Result<Stateful<S,A>,E>``
- ``<*(_:_:)->Result<Writer<W,A>,E>``

**Publisher**
- ``*>(_:_:)->AnyPublisher<Either<L,B>,E>``
- ``*>(_:_:)->AnyPublisher<Stateful<S,B>,E>``
- ``*>(_:_:)->AnyPublisher<Writer<W,B>,E>``
- ``<*(_:_:)->AnyPublisher<Either<L,A>,E>``
- ``<*(_:_:)->AnyPublisher<Stateful<S,A>,E>``
- ``<*(_:_:)->AnyPublisher<Writer<W,A>,E>``

**AsyncSequence**
- ``*>(_:_:)->AsyncStream<Either<L,B>>``
- ``<*(_:_:)->AsyncStream<Either<L,A>>``

### Monad — `>>-` / `-<<` (bind, container-left / fn-left)

**Either**
- ``>>-(_:_:)->Either<A,B1>``
- ``>>-(_:_:)->Either<L,B>?``
- ``>>-(_:_:)->Either<L,B?>``
- ``>>-(_:_:)->Either<L,NonEmpty<B>?>``
- ``>>-(_:_:)->Either<L,Result<B,E>>``
- ``>>-(_:_:)->Either<L,Stateful<S,B>>``
- ``>>-(_:_:)->Either<L,Writer<W,B>>``
- ``>>-(_:_:)->Either<L,[B]>``
- ``>>-(_:_:)->[Either<L,B>]``
- ``-<<(_:_:)->Either<A,B1>``
- ``-<<(_:_:)->Either<L,B>?``
- ``-<<(_:_:)->Either<L,B?>``
- ``-<<(_:_:)->Either<L,NonEmpty<B>?>``
- ``-<<(_:_:)->Either<L,Result<B,E>>``
- ``-<<(_:_:)->Either<L,Stateful<S,B>>``
- ``-<<(_:_:)->Either<L,Writer<W,B>>``
- ``-<<(_:_:)->Either<L,[B]>``
- ``-<<(_:_:)->[Either<L,B>]``

**These**
- ``>>-(_:_:)->These<A,C>``
- ``-<<(_:_:)->These<A,C>``

**Reader**
- ``>>-(_:_:)->Reader<Env,AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>,B>,B>>``
- ``>>-(_:_:)->Reader<Env,B?>``
- ``>>-(_:_:)->Reader<Env,Either<L,B>>``
- ``>>-(_:_:)->Reader<Env,NonEmpty<B>?>``
- ``>>-(_:_:)->Reader<Env,O1>``
- ``>>-(_:_:)->Reader<Env,Publisher<B,E>>``
- ``>>-(_:_:)->Reader<Env,Result<B,E>>``
- ``>>-(_:_:)->Reader<Env,Stateful<S,B>>``
- ``>>-(_:_:)->Reader<Env,Writer<W,B>>``
- ``>>-(_:_:)->Reader<Env,[B]>``
- ``>>-(_:_:)->Reader<Env1,Reader<Env2,B>>``
- ``-<<(_:_:)->Reader<Env,AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>,B>,B>>``
- ``-<<(_:_:)->Reader<Env,B?>``
- ``-<<(_:_:)->Reader<Env,Either<L,B>>``
- ``-<<(_:_:)->Reader<Env,NonEmpty<B>?>``
- ``-<<(_:_:)->Reader<Env,O1>``
- ``-<<(_:_:)->Reader<Env,Publisher<B,E>>``
- ``-<<(_:_:)->Reader<Env,Result<B,E>>``
- ``-<<(_:_:)->Reader<Env,Stateful<S,B>>``
- ``-<<(_:_:)->Reader<Env,Writer<W,B>>``
- ``-<<(_:_:)->Reader<Env,[B]>``
- ``-<<(_:_:)->Reader<Env1,Reader<Env2,B>>``

**Writer**
- ``>>-(_:_:)->Writer<W,AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>,B>,B>>``
- ``>>-(_:_:)->Writer<W,B>?``
- ``>>-(_:_:)->Writer<W,B>``
- ``>>-(_:_:)->Writer<W,B?>``
- ``>>-(_:_:)->Writer<W,Either<L,B>>``
- ``>>-(_:_:)->Writer<W,NonEmpty<B>?>``
- ``>>-(_:_:)->Writer<W,Publisher<B,E>>``
- ``>>-(_:_:)->Writer<W,Reader<Env,B>>``
- ``>>-(_:_:)->Writer<W,Result<B,E>>``
- ``>>-(_:_:)->Writer<W,Stateful<S,B>>``
- ``>>-(_:_:)->Writer<W,[B]>``
- ``>>-(_:_:)->[Writer<W,B>]``
- ``-<<(_:_:)->Writer<W,AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>,B>,B>>``
- ``-<<(_:_:)->Writer<W,B>?``
- ``-<<(_:_:)->Writer<W,B>``
- ``-<<(_:_:)->Writer<W,B?>``
- ``-<<(_:_:)->Writer<W,Either<L,B>>``
- ``-<<(_:_:)->Writer<W,NonEmpty<B>?>``
- ``-<<(_:_:)->Writer<W,Publisher<B,E>>``
- ``-<<(_:_:)->Writer<W,Reader<Env,B>>``
- ``-<<(_:_:)->Writer<W,Result<B,E>>``
- ``-<<(_:_:)->Writer<W,Stateful<S,B>>``
- ``-<<(_:_:)->Writer<W,[B]>``
- ``-<<(_:_:)->[Writer<W,B>]``

**Stateful**
- ``>>-(_:_:)->Stateful<S,B>?``
- ``>>-(_:_:)->Stateful<S,B>``
- ``>>-(_:_:)->Stateful<S,B?>``
- ``>>-(_:_:)->Stateful<S,Either<L,B>>``
- ``>>-(_:_:)->Stateful<S,NonEmpty<B>?>``
- ``>>-(_:_:)->Stateful<S,Result<B,E>>``
- ``>>-(_:_:)->Stateful<S,Writer<W,B>>``
- ``>>-(_:_:)->Stateful<S,[B]>``
- ``>>-(_:_:)->[Stateful<S,B>]``
- ``-<<(_:_:)->Stateful<S,B>?``
- ``-<<(_:_:)->Stateful<S,B>``
- ``-<<(_:_:)->Stateful<S,B?>``
- ``-<<(_:_:)->Stateful<S,Either<L,B>>``
- ``-<<(_:_:)->Stateful<S,NonEmpty<B>?>``
- ``-<<(_:_:)->Stateful<S,Result<B,E>>``
- ``-<<(_:_:)->Stateful<S,Writer<W,B>>``
- ``-<<(_:_:)->Stateful<S,[B]>``
- ``-<<(_:_:)->[Stateful<S,B>]``

**Loading**
- ``>>-(_:_:)->Loading<B,F>``
- ``-<<(_:_:)->Loading<B,F>``

**NonEmpty**
- ``>>-(_:_:)->NonEmpty<B>?``
- ``>>-(_:_:)->NonEmpty<B>``
- ``>>-(_:_:)->NonEmpty<B?>``
- ``>>-(_:_:)->NonEmpty<Either<L,B>>``
- ``>>-(_:_:)->NonEmpty<Result<B,E>>``
- ``-<<(_:_:)->NonEmpty<B>?``
- ``-<<(_:_:)->NonEmpty<B>``
- ``-<<(_:_:)->NonEmpty<B?>``
- ``-<<(_:_:)->NonEmpty<Either<L,B>>``
- ``-<<(_:_:)->NonEmpty<Result<B,E>>``

**Result**
- ``>>-(_:_:)->Result<Stateful<S,B>,E>``
- ``>>-(_:_:)->Result<Writer<W,B>,E>``
- ``-<<(_:_:)->Result<Stateful<S,B>,E>``
- ``-<<(_:_:)->Result<Writer<W,B>,E>``

**Publisher**
- ``>>-(_:_:)->AnyPublisher<Either<L,B>,E>``
- ``>>-(_:_:)->AnyPublisher<Stateful<S,B>,E>``
- ``>>-(_:_:)->AnyPublisher<Writer<W,B>,E>``
- ``-<<(_:_:)->AnyPublisher<Either<L,B>,E>``
- ``-<<(_:_:)->AnyPublisher<Stateful<S,B>,E>``
- ``-<<(_:_:)->AnyPublisher<Writer<W,B>,E>``

**AsyncSequence**
- ``>>-(_:_:)->AsyncMapSequence<AsyncStream<Stateful<S,A>>,Stateful<S,B>>``
- ``>>-(_:_:)->AsyncMapSequence<AsyncStream<Writer<W,A>>,Writer<W,B>>``
- ``>>-(_:_:)->AsyncStream<Either<L,B>>``
- ``-<<(_:_:)->AsyncMapSequence<AsyncStream<Stateful<S,A>>,Stateful<S,B>>``
- ``-<<(_:_:)->AsyncMapSequence<AsyncStream<Writer<W,A>>,Writer<W,B>>``
- ``-<<(_:_:)->AsyncStream<Either<L,B>>``

### Kleisli Composition — `>=>` / `<=<`

**Either**
- ``>=>(_:_:)-22fj0``
- ``>=>(_:_:)-667gm``
- ``>=>(_:_:)-7axoy``
- ``>=>(_:_:)-8j2fu``
- ``>=>(_:_:)-8t8ih``
- ``>=>(_:_:)-91p9a``
- ``>=>(_:_:)-9h3y9``
- ``>=>(_:_:)-9nbl3``
- ``>=>(_:_:)-9vqo1``
- ``<=<(_:_:)-1yz12``
- ``<=<(_:_:)-39br2``
- ``<=<(_:_:)-4f82i``
- ``<=<(_:_:)-5d2oo``
- ``<=<(_:_:)-6fvyf``
- ``<=<(_:_:)-6st1d``
- ``<=<(_:_:)-9090w``
- ``<=<(_:_:)-9n6r9``
- ``<=<(_:_:)-cvfb``

**These**
- ``>=>(_:_:)-7dfrv``
- ``<=<(_:_:)-34g5d``

**Reader**
- ``>=>(_:_:)-4nbnr``
- ``>=>(_:_:)-6e2wo``
- ``>=>(_:_:)-6f6be``
- ``>=>(_:_:)-6go0b``
- ``>=>(_:_:)-6ikcu``
- ``>=>(_:_:)-6n0rm``
- ``>=>(_:_:)-84isw``
- ``>=>(_:_:)-8nbue``
- ``>=>(_:_:)-9qtvh``
- ``>=>(_:_:)-j111``
- ``<=<(_:_:)-47q8m``
- ``<=<(_:_:)-4hvaj``
- ``<=<(_:_:)-5ehmm``
- ``<=<(_:_:)-79npn``
- ``<=<(_:_:)-7v7dp``
- ``<=<(_:_:)-7vy7c``
- ``<=<(_:_:)-7zb3``
- ``<=<(_:_:)-8iylz``
- ``<=<(_:_:)-97qjt``
- ``<=<(_:_:)-niqs``

**Writer**
- ``>=>(_:_:)-2uamx``
- ``>=>(_:_:)-3o4dx``
- ``>=>(_:_:)-6i256``
- ``>=>(_:_:)-70n3q``
- ``>=>(_:_:)-7i2bu``
- ``>=>(_:_:)-8ol6x``
- ``>=>(_:_:)-990ez``
- ``>=>(_:_:)-9ruwk``
- ``>=>(_:_:)-9ysl7``
- ``>=>(_:_:)-mfe6``
- ``>=>(_:_:)-v7m5``
- ``<=<(_:_:)-28fwq``
- ``<=<(_:_:)-2ymd3``
- ``<=<(_:_:)-423j``
- ``<=<(_:_:)-4lamj``
- ``<=<(_:_:)-53kz0``
- ``<=<(_:_:)-5dlgy``
- ``<=<(_:_:)-5fgv3``
- ``<=<(_:_:)-6eb32``
- ``<=<(_:_:)-7e0tb``
- ``<=<(_:_:)-7v0z2``
- ``<=<(_:_:)-87p0k``

**Stateful**
- ``>=>(_:_:)-24eoy``
- ``>=>(_:_:)-44zhy``
- ``>=>(_:_:)-45fev``
- ``>=>(_:_:)-4wj0x``
- ``>=>(_:_:)-5asdk``
- ``>=>(_:_:)-6u7oj``
- ``>=>(_:_:)-8gv7i``
- ``>=>(_:_:)-izqp``
- ``<=<(_:_:)-14x7n``
- ``<=<(_:_:)-2f87q``
- ``<=<(_:_:)-2t6vy``
- ``<=<(_:_:)-34yhk``
- ``<=<(_:_:)-3t711``
- ``<=<(_:_:)-58bq6``
- ``<=<(_:_:)-9aw0t``
- ``<=<(_:_:)-9axxj``

**Loading**
- ``>=>(_:_:)-9l9eq``
- ``<=<(_:_:)-20dcg``

**NonEmpty**
- ``>=>(_:_:)-23729``
- ``>=>(_:_:)-2m5ro``
- ``>=>(_:_:)-8i4dl``
- ``>=>(_:_:)-9ddux``
- ``>=>(_:_:)-cpss``
- ``<=<(_:_:)-5zd2e``
- ``<=<(_:_:)-64vq9``
- ``<=<(_:_:)-7az9g``
- ``<=<(_:_:)-7uusw``
- ``<=<(_:_:)-j60q``

**Result**
- ``>=>(_:_:)-75696``
- ``>=>(_:_:)-9okfg``
- ``<=<(_:_:)-59iwt``
- ``<=<(_:_:)-7egvf``

### Alternative — `<|>` (choice)

**Either**
- ``<|>(_:_:)->Either<A,B>``

**Validation**
- ``<|>(_:_:)->Validation<E,A>``

### Comonad — `->>` / `<<-` (extend, container-left / fn-left)

- ``->>(_:_:)->NonEmpty<B>``
- ``->>(_:_:)->Zipper<B>``
- ``->>(_:_:)->Reader<Env,B>``
- ``->>(_:_:)->Writer<W,B>``
- ``<<-(_:_:)->NonEmpty<B>``
- ``<<-(_:_:)->Zipper<B>``
- ``<<-(_:_:)->Reader<Env,B>``
- ``<<-(_:_:)->Writer<W,B>``

### Function Application — `<£` / `£>` (constant replace)

**Either**
- ``<£(_:_:)->Either<A,B1>``
- ``£>(_:_:)->Either<A,B1>``

**Validation**
- ``<£(_:_:)->Validation<E,B>``
- ``£>(_:_:)->Validation<E,B>``

**These**
- ``<£(_:_:)->These<A,B1>``
- ``£>(_:_:)->These<A,B1>``

**Reader**
- ``<£(_:_:)->Reader<Env,A1?>``
- ``<£(_:_:)->Reader<Env,AsyncMapSequence<AsyncStream<B>,A>>``
- ``<£(_:_:)->Reader<Env,B>``
- ``<£(_:_:)->Reader<Env,Either<A,B1>>``
- ``<£(_:_:)->Reader<Env,Publisher<A1,B>>``
- ``<£(_:_:)->Reader<Env,Result<A1,B>>``
- ``<£(_:_:)->Reader<Env,[A]>``
- ``<£(_:_:)->Reader<Env1,Reader<Env2,A>>``
- ``£>(_:_:)->Reader<Env,A1?>``
- ``£>(_:_:)->Reader<Env,AsyncMapSequence<AsyncStream<A>,B>>``
- ``£>(_:_:)->Reader<Env,B>``
- ``£>(_:_:)->Reader<Env,Either<A,B1>>``
- ``£>(_:_:)->Reader<Env,Publisher<A1,B>>``
- ``£>(_:_:)->Reader<Env,Result<A1,B>>``
- ``£>(_:_:)->Reader<Env,[B]>``
- ``£>(_:_:)->Reader<Env1,Reader<Env2,B>>``

**Writer**
- ``<£(_:_:)->Writer<W,B>``
- ``£>(_:_:)->Writer<W,B>``

**Stateful**
- ``<£(_:_:)->Stateful<S,B>``
- ``£>(_:_:)->Stateful<S,B>``

**Loading**
- ``<£(_:_:)->Loading<B,F>``
- ``£>(_:_:)->Loading<B,F>``

**NonEmpty**
- ``<£(_:_:)->NonEmpty<B>``
- ``£>(_:_:)->NonEmpty<B>``

**Zipper**
- ``<£(_:_:)->Zipper<B>``
- ``£>(_:_:)->Zipper<B>``


