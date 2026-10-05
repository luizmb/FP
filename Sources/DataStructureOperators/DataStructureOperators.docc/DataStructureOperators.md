# ``DataStructureOperators``

The operator syntax for everything in `DataStructure`: Functor/Applicative/Monad operators for `Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, `NonEmpty`, `These`, `Zipper`, plus the operators of every transformer stack struct (`ReaderTArray`, `StatefulTEither`, …) with a `DataStructure` layer.

## Overview

Every operator here delegates to a named function in [DataStructure](../datastructure) — the operator module never implements logic itself, only syntax. Import both modules together (or the [FP](../fp) umbrella, which re-exports everything):

```swift
import DataStructure
import DataStructureOperators

let parsed = Either<String, Int>.right(5) >>- { n in n > 0 ? .right(n) : .left("negative") }
```

The full, verified operator/precedence table across both `CoreFPOperators` and `DataStructureOperators` lives in [OperatorVocabulary](../fp/operatorvocabulary).

Every operator here is heavily overloaded, one per type it applies to (`Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, `NonEmpty`, `These`, `Zipper`, and every transformer stack struct). Grouped below by mathematical concept, then by type.

The transformer stack structs in `DataStructure` (`ReaderTArray`, `StatefulTEither`, `WriterTOptional`, …) get the same operators on their own type: `<£>`, `<&>`, `£>`, `<£`, `<*>`, `*>`, `<*`, and on lawful monad stacks (`MonadT`) also `>>-`, `-<<`, `>=>`, `<=<`. They are generated next to the structs (`Sources/DataStructureOperators/Transformer/Generated/`) and each one delegates to the struct's named method (`map`, `apply`, `seqRight`, `flatMap`, `kleisli`, …), so they are not listed one by one in the topics below. There are no operator overloads on bare nested values (`Reader<Env, [A]>`): wrap the value in its stack first (`reader.readerT`). See [MonadTransformers](../fp/monadtransformers).

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

### Applicative — `<*>` (apply), `*>` / `<*` (sequence)

**Either**
- ``<*>(_:_:)->Either<A,B>``
- ``*>(_:_:)->Either<A,B>``
- ``<*(_:_:)->Either<A,B>``

**Validation**
- ``<*>(_:_:)->Validation<E,B>``
- ``*>(_:_:)->Validation<E,B>``
- ``<*(_:_:)->Validation<E,A>``

**These**
- ``<*>(_:_:)->These<A,C>``
- ``*>(_:_:)->These<A,B>``
- ``<*(_:_:)->These<A,B>``

**Reader**
- ``<*>(_:_:)->Reader<Env,B>``
- ``*>(_:_:)->Reader<Env,B>``
- ``<*(_:_:)->Reader<Env,A>``

**Writer**
- ``<*>(_:_:)->Writer<W,B>``
- ``*>(_:_:)->Writer<W,B>``
- ``<*(_:_:)->Writer<W,A>``

**Stateful**
- ``<*>(_:_:)->Stateful<S,B>``
- ``*>(_:_:)->Stateful<S,B>``
- ``<*(_:_:)->Stateful<S,A>``

**Loading**
- ``<*>(_:_:)->Loading<S,F>``
- ``*>(_:_:)->Loading<S,F>``
- ``<*(_:_:)->Loading<S,F>``

**NonEmpty**
- ``<*>(_:_:)->NonEmpty<B>``
- ``*>(_:_:)->NonEmpty<B>``
- ``<*(_:_:)->NonEmpty<A>``
### Monad — `>>-` / `-<<` (bind, container-left / fn-left)

**Either**
- ``>>-(_:_:)->Either<A,B1>``
- ``-<<(_:_:)->Either<A,B1>``

**These**
- ``>>-(_:_:)->These<A,C>``
- ``-<<(_:_:)->These<A,C>``

**Reader**
- ``>>-(_:_:)->Reader<Env,O1>``
- ``-<<(_:_:)->Reader<Env,O1>``

**Writer**
- ``>>-(_:_:)->Writer<W,B>``
- ``-<<(_:_:)->Writer<W,B>``

**Stateful**
- ``>>-(_:_:)->Stateful<S,B>``
- ``-<<(_:_:)->Stateful<S,B>``

**Loading**
- ``>>-(_:_:)->Loading<B,F>``
- ``-<<(_:_:)->Loading<B,F>``

**NonEmpty**
- ``>>-(_:_:)->NonEmpty<B>``
- ``-<<(_:_:)->NonEmpty<B>``
### Kleisli Composition — `>=>` / `<=<`

**Either**
- ``>=>(_:_:)-19ix6``
- ``<=<(_:_:)-5y138``

**These**
- ``>=>(_:_:)-7eb3b``
- ``<=<(_:_:)-8c4h0``

**Reader**
- ``>=>(_:_:)-7kvyc``
- ``<=<(_:_:)-55fw2``

**Writer**
- ``>=>(_:_:)-826pk``
- ``<=<(_:_:)-6k0ge``

**Stateful**
- ``>=>(_:_:)-5o5y2``
- ``<=<(_:_:)-1xjx``

**Loading**
- ``>=>(_:_:)-8vajy``
- ``<=<(_:_:)-7mcab``

**NonEmpty**
- ``>=>(_:_:)-7dx5t``
- ``<=<(_:_:)-3nwpt``
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
- ``<£(_:_:)->Reader<Env,B>``
- ``£>(_:_:)->Reader<Env,B>``

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

