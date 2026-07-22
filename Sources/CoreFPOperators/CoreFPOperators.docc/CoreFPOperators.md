# ``CoreFPOperators``

The operator syntax for everything in `CoreFP` — Functor/Applicative/Monad operators for `Optional`, `Result`, `Array`, `Combine.Publisher`, `AsyncSequence`, and function composition (`>>>`, `<<<`, `|>`, `£`).

## Overview

Every operator here delegates to a named function in [CoreFP](../corefp) — the operator module never implements logic itself, only syntax. Import both modules together (or the [FP](../fp) umbrella, which re-exports everything):

```swift
import CoreFP
import CoreFPOperators

let result = { $0 * 2 } <£> Optional(5)   // Optional(10)
```

The full, verified operator/precedence table across both `CoreFPOperators` and `DataStructureOperators` lives in [OperatorVocabulary](../fp/operatorvocabulary).

Every operator here is heavily overloaded — one per type it applies to (`Optional`, `Result`, `Array`, `Publisher`, `AsyncSequence`, and every transformer combo between them). Grouped below by mathematical concept, then by type.

## Related Modules

| Module | Contents |
|--------|----------|
| [FP (umbrella)](../fp) | Re-exports all four modules; also the home of cross-cutting conceptual articles |
| [CoreFP](../corefp) | Named functions this module's operators delegate to |
| [DataStructure](../datastructure) | The library's own algebraic and effect types |
| [DataStructureOperators](../datastructureoperators) | Operator syntax for `DataStructure` |

## Topics

### Functor — `<£>` / `<&>` (fn-left / container-left), `<£^>` / `<&^>` (transformer)

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

Transformer (nested) functor map:
- ``<£^>(_:_:)->[B?]``
- ``<£^>(_:_:)->[B]?``
- ``<£^>(_:_:)->Result<B,E>?``
- ``<£^>(_:_:)->[Result<B,E>]``
- ``<£^>(_:_:)->AnyPublisher<B?,E>``
- ``<£^>(_:_:)->AnyPublisher<Result<B,E2>,E>``
- ``<£^>(_:_:)->AnyPublisher<[B],E>``
- ``<£^>(_:_:)->AsyncStream<B?>``
- ``<£^>(_:_:)->AsyncStream<Result<B,E>>``
- ``<£^>(_:_:)->AsyncStream<[B]>``
- ``<&^>(_:_:)->[B?]``
- ``<&^>(_:_:)->[B]?``
- ``<&^>(_:_:)->Result<B,E>?``
- ``<&^>(_:_:)->[Result<B,E>]``
- ``<&^>(_:_:)->AnyPublisher<B?,E>``
- ``<&^>(_:_:)->AnyPublisher<Result<B,E2>,E>``
- ``<&^>(_:_:)->AnyPublisher<[B],E>``
- ``<&^>(_:_:)->AsyncStream<B?>``
- ``<&^>(_:_:)->AsyncStream<Result<B,E>>``
- ``<&^>(_:_:)->AsyncStream<[B]>``

### Applicative — `<*>` (apply), `*>` / `<*` (sequence, keep right/left)

- ``<*>(_:_:)->A?``
- ``<*>(_:_:)->[A1]``
- ``<*>(_:_:)->[B?]``
- ``<*>(_:_:)->[B]?``
- ``<*>(_:_:)->Result<A,B>``
- ``<*>(_:_:)->Result<B,E>?``
- ``<*>(_:_:)->[Result<B,E>]``
- ``<*>(_:_:)->Publisher<A,B>``
- ``<*>(_:_:)->AsyncStream<B>``
- ``<*>(_:_:)-3ixm5``
- ``*>(_:_:)->A?``
- ``*>(_:_:)->[A1]``
- ``*>(_:_:)->[B?]``
- ``*>(_:_:)->[B]?``
- ``*>(_:_:)->Result<A,B>``
- ``*>(_:_:)->Result<B,E>?``
- ``*>(_:_:)->[Result<B,E>]``
- ``*>(_:_:)->AnyPublisher<B?,E>``
- ``*>(_:_:)->AnyPublisher<Result<B,E2>,E>``
- ``*>(_:_:)->AnyPublisher<[B],E>``
- ``*>(_:_:)->Publisher<A,B>``
- ``*>(_:_:)->AsyncStream<B>``
- ``*>(_:_:)->AsyncStream<B?>``
- ``*>(_:_:)->AsyncStream<Result<B,E>>``
- ``*>(_:_:)->AsyncStream<[B]>``
- ``*>(_:_:)-202n9``
- ``<*(_:_:)->A?``
- ``<*(_:_:)->[A?]``
- ``<*(_:_:)->[A]``
- ``<*(_:_:)->[A]?``
- ``<*(_:_:)->Result<A,B>``
- ``<*(_:_:)->Result<A,E>?``
- ``<*(_:_:)->[Result<A,E>]``
- ``<*(_:_:)->AnyPublisher<A?,E>``
- ``<*(_:_:)->AnyPublisher<Result<A,E2>,E>``
- ``<*(_:_:)->AnyPublisher<[A],E>``
- ``<*(_:_:)->Publisher<A,B>``
- ``<*(_:_:)->AsyncStream<A>``
- ``<*(_:_:)->AsyncStream<A?>``
- ``<*(_:_:)->AsyncStream<Result<A,E>>``
- ``<*(_:_:)->AsyncStream<[A]>``
- ``<*(_:_:)-4d1wn``

### Monad — `>>-` / `-<<` (bind, container-left / fn-left)

- ``>>-(_:_:)->A1?``
- ``>>-(_:_:)->[A1]``
- ``>>-(_:_:)->[B?]``
- ``>>-(_:_:)->[B]?``
- ``>>-(_:_:)->Result<A1,B>``
- ``>>-(_:_:)->Result<B,E>?``
- ``>>-(_:_:)->[Result<B,E>]``
- ``>>-(_:_:)->AnyPublisher<B?,E>``
- ``>>-(_:_:)->AnyPublisher<Result<B,E2>,E>``
- ``>>-(_:_:)->AnyPublisher<[B],E>``
- ``>>-(_:_:)->Publisher<A1,B>``
- ``>>-(_:_:)->AsyncStream<B?>``
- ``>>-(_:_:)->AsyncStream<Result<B,E>>``
- ``>>-(_:_:)->AsyncStream<[B]>``
- ``>>-(_:_:)->AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<S,T>,T>``
- ``>>-(_:_:)-3rvkc``
- ``-<<(_:_:)->A1?``
- ``-<<(_:_:)->[A1]``
- ``-<<(_:_:)->[B?]``
- ``-<<(_:_:)->[B]?``
- ``-<<(_:_:)->Result<A1,B>``
- ``-<<(_:_:)->Result<B,E>?``
- ``-<<(_:_:)->[Result<B,E>]``
- ``-<<(_:_:)->AnyPublisher<B?,E>``
- ``-<<(_:_:)->AnyPublisher<Result<B,E2>,E>``
- ``-<<(_:_:)->AnyPublisher<[B],E>``
- ``-<<(_:_:)->Publisher<A1,B>``
- ``-<<(_:_:)->AsyncStream<B?>``
- ``-<<(_:_:)->AsyncStream<Result<B,E>>``
- ``-<<(_:_:)->AsyncStream<[B]>``
- ``-<<(_:_:)->AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<S,T>,T>``
- ``-<<(_:_:)-4ni60``

### Kleisli Composition — `>=>` / `<=<` (left-to-right / right-to-left)

- ``>=>(_:_:)-2ytfj``
- ``>=>(_:_:)-9eudm``
- ``>=>(_:_:)-93wat``
- ``>=>(_:_:)-8x1ft``
- ``>=>(_:_:)-913mw``
- ``>=>(_:_:)-9mebb``
- ``>=>(_:_:)-1ym4s``
- ``>=>(_:_:)-frcl``
- ``>=>(_:_:)-7cz88``
- ``>=>(_:_:)-9wi7y``
- ``<=<(_:_:)-50t7s``
- ``<=<(_:_:)-5zndc``
- ``<=<(_:_:)-479op``
- ``<=<(_:_:)-72b04``
- ``<=<(_:_:)-4lxyd``
- ``<=<(_:_:)-61eoz``
- ``<=<(_:_:)-61bjj``
- ``<=<(_:_:)-5uljc``
- ``<=<(_:_:)-pur6``
- ``<=<(_:_:)-7yduy``

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

### Function Application — `£` / `<|` (fn-left), `|>` (value-left)

- ``£(_:_:)``
- ``<|(_:_:)``
- ``|>(_:_:)``

### Semigroup & Monoid Append — `<>`, `++`

- ``<>(_:_:)``
- ``++(_:_:)``

### Numeric Ranges & Isomorphism — `^`, `+/-` / `±`, `≅`

- ``^(_:_:)``
- ``+/-(_:_:)``
- ``≅(_:_:)-(_,ClosedRange<T>)``
- ``≅(_:_:)-(_,PartialRangeFrom<T>)``
- ``≅(_:_:)-(_,PartialRangeThrough<T>)``
- ``≅(_:_:)-(_,PartialRangeUpTo<T>)``
- ``≅(_:_:)-(_,Range<T>)``
