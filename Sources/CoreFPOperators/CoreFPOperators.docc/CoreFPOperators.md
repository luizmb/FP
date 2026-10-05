# ``CoreFPOperators``

The operator syntax for everything in `CoreFP` — Functor/Applicative/Monad operators for `Optional`, `Result`, `Array`, `Combine.Publisher`, `AsyncSequence`, and function composition (`>>>`, `<<<`, `|>`, `<|`).

## Overview

Every operator here delegates to a named function in [CoreFP](../corefp) — the operator module never implements logic itself, only syntax. Import both modules together (or the [FP](../fp) umbrella, which re-exports everything):

```swift
import CoreFP
import CoreFPOperators

let result = { $0 * 2 } <£> Optional(5)   // Optional(10)
```

The full, verified operator/precedence table across both `CoreFPOperators` and `DataStructureOperators` lives in [OperatorVocabulary](../fp/operatorvocabulary).

Every operator here is heavily overloaded, one per type it applies to (`Optional`, `Result`, `Array`, `Publisher`, `AsyncSequence`, and every transformer stack struct). Grouped below by mathematical concept, then by type.

The transformer stack structs in `CoreFP` (`OptionalTArray`, `ArrayTResult`, `PublisherTOptional`, `AsyncStreamTResult`, …) get `<£>`, `<&>`, `£>`, `<£`, `<*>`, `*>`, `<*` on their own type, plus `>>-`, `-<<`, `>=>`, `<=<` on lawful monad stacks (`MonadT`). They are generated (`Sources/CoreFPOperators/Transformer/Generated/`), delegate to the struct's named methods, and are not listed one by one below. There are no operator overloads on bare nested values (`[A?]`, `AnyPublisher<[A], E>`): wrap the value in its stack first (`array.arrayT`, `publisher.publisherT`). See [MonadTransformers](../fp/monadtransformers).

## Related Modules

| Module | Contents |
|--------|----------|
| [FP (umbrella)](../fp) | Re-exports all four modules; also the home of cross-cutting conceptual articles |
| [CoreFP](../corefp) | Named functions this module's operators delegate to |
| [DataStructure](../datastructure) | The library's own algebraic and effect types |
| [DataStructureOperators](../datastructureoperators) | Operator syntax for `DataStructure` |

## Topics

### Functor — `<£>` / `<&>` (fn-left / container-left)

- ``<£(_:_:)->A1?``
- ``<£(_:_:)->[A1]``
- ``<£(_:_:)->Result<A1,B>``
- ``<£(_:_:)->Publisher<A1,B>``
- ``<£(_:_:)->AsyncThrowingMapSequence<S,T>``
- ``<£(_:_:)-9f5ge``
- ``£>(_:_:)->A1?``
- ``£>(_:_:)->[A1]``
- ``£>(_:_:)->Result<A1,B>``
- ``£>(_:_:)->Publisher<A1,B>``
- ``£>(_:_:)->AsyncThrowingMapSequence<S,T>``
- ``£>(_:_:)-4jmtf``
- ``<£>(_:_:)->A1?``
- ``<£>(_:_:)->[A1]``
- ``<£>(_:_:)->Result<A1,B>``
- ``<£>(_:_:)->Publisher<A1,B>``
- ``<£>(_:_:)->AsyncThrowingMapSequence<S,T>``
- ``<£>(_:_:)-3qiw8``
- ``<&>(_:_:)->A1?``
- ``<&>(_:_:)->[A1]``
- ``<&>(_:_:)->Result<A1,B>``
- ``<&>(_:_:)->Publisher<A1,B>``
- ``<&>(_:_:)->AsyncThrowingMapSequence<S,T>``
- ``<&>(_:_:)-4yuvj``

### Applicative — `<*>` (apply), `*>` / `<*` (sequence, keep right/left)

- ``<*>(_:_:)->A?``
- ``<*>(_:_:)->[A1]``
- ``<*>(_:_:)->Result<A,B>``
- ``<*>(_:_:)->Publisher<A,B>``
- ``<*>(_:_:)->AsyncStream<B>``
- ``<*>(_:_:)-3ixm5``
- ``*>(_:_:)->A?``
- ``*>(_:_:)->[A1]``
- ``*>(_:_:)->Result<A,B>``
- ``*>(_:_:)->Publisher<A,B>``
- ``*>(_:_:)->AsyncStream<B>``
- ``*>(_:_:)-202n9``
- ``<*(_:_:)->A?``
- ``<*(_:_:)->[A]``
- ``<*(_:_:)->Result<A,B>``
- ``<*(_:_:)->Publisher<A,B>``
- ``<*(_:_:)->AsyncStream<A>``
- ``<*(_:_:)-4d1wn``

### Monad — `>>-` / `-<<` (bind, container-left / fn-left)

- ``>>-(_:_:)->A1?``
- ``>>-(_:_:)->[A1]``
- ``>>-(_:_:)->Result<A1,B>``
- ``>>-(_:_:)->Publisher<A1,B>``
- ``>>-(_:_:)->AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<S,T>,T>``
- ``>>-(_:_:)-3rvkc``
- ``-<<(_:_:)->A1?``
- ``-<<(_:_:)->[A1]``
- ``-<<(_:_:)->Result<A1,B>``
- ``-<<(_:_:)->Publisher<A1,B>``
- ``-<<(_:_:)->AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<S,T>,T>``
- ``-<<(_:_:)-4ni60``

### Kleisli Composition — `>=>` / `<=<` (left-to-right / right-to-left)

- ``>=>(_:_:)-8e1dv``
- ``>=>(_:_:)-50pt``
- ``>=>(_:_:)-9twdt``
- ``>=>(_:_:)-7tcmj``
- ``>=>(_:_:)-5ppgu``
- ``>=>(_:_:)-6q2cc``
- ``<=<(_:_:)-4d759``
- ``<=<(_:_:)-7hfw7``
- ``<=<(_:_:)-939h``
- ``<=<(_:_:)-60ib1``
- ``<=<(_:_:)-2ps07``
- ``<=<(_:_:)-39pb0``

### Alternative — `<|>` (choice, first success wins)

- ``<|>(_:_:)->A?``
- ``<|>(_:_:)->[A]``
- ``<|>(_:_:)->Result<A,B>``
- ``<|>(_:_:)->Publisher<A,E>``

### Function & Optics Composition — `>>>` / `<<<` (left-to-right / right-to-left)

- ``>>>(_:_:)-8mchz``
- ``<<<(_:_:)-88ssq``

`>>>`/`<<<` are also heavily overloaded for optics (`Lens`, `Prism`, `Iso`, `AffineTraversal`, `Traversal`, `IndexedTraversal` — 26 combinations each direction) — see [Optics](../corefp/optics) for the full composition matrix rather than a flat list here.

A **variadic** overload of each direction composes a tuple-producing function (a `fanout`) with a
multi-argument function, bridging the SE-0110 gap between a tuple argument and a multi-argument parameter
list: `fanout(\.badge, \.save) >>> Env.init`. It coexists with the single-argument overload without
ambiguity — see [Point-Free Style](../corefp/pointfreestyle) for the worked example.

### Function Application — `<|` (fn-left), `|>` (value-left)

- ``<|(_:_:)``
- ``|>(_:_:)``

### Semigroup & Monoid Append — `<>`

- ``<>(_:_:)``

### Numeric Ranges & Isomorphism — `^`, `+/-` / `±`, `≅`

- ``^(_:_:)``
- ``+/-(_:_:)``
- ``≅(_:_:)-(_,ClosedRange<T>)``
- ``≅(_:_:)-(_,PartialRangeFrom<T>)``
- ``≅(_:_:)-(_,PartialRangeThrough<T>)``
- ``≅(_:_:)-(_,PartialRangeUpTo<T>)``
- ``≅(_:_:)-(_,Range<T>)``
