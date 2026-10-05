# ``DataStructure``

The library's own algebraic and effect types: sum types, monad-transformer stacks, and the property-based-testing generator.

## Overview

`DataStructure` is where the library's actual named types live — as opposed to [CoreFP](../corefp), which extends types you don't own (`Optional`, `Result`, `Array`, `Combine.Publisher`) and provides the optics/algebra foundation everything else builds on.

```swift
import DataStructure

let parsed: Either<String, Int> = Int("42").map(Either.right) ?? .left("not a number")

struct Config: Sendable { var port: Int }

let reader = Reader<Config, Int?> { $0.port > 0 ? $0.port : nil }
let doubled = reader.readerT.map { $0 * 2 }   // ReaderTOptional<Config, Int>
let backToReader = doubled.rawValue           // Reader<Config, Int?>
```

Import [DataStructureOperators](../datastructureoperators) alongside this module for the operator syntax (`<£>`, `<*>`, `>>-`, `>=>`, …); the full precedence table is in [OperatorVocabulary](../fp/operatorvocabulary). Every monad-transformer stack with a `DataStructure` layer is its own struct here, named `OuterTInner` (`ReaderTEither<Env, L, A>` wraps `Reader<Env, Either<L, A>>`): lift a nested value in with the property on the outer type (`reader.readerT`) or `ReaderTEither(reader)`, use `map` / `apply` / `flatMap` or the operators, and leave with `.rawValue`. The model is explained in [MonadTransformers](../fp/monadtransformers); the protocols (`TransformerStack`, `MonadT`) and the stacks made only of `CoreFP` types live in [CoreFP](../corefp).

## Related Modules

| Module | Contents |
|--------|----------|
| [FP (umbrella)](../fp) | Re-exports all four modules; also the home of cross-cutting conceptual articles |
| [CoreFP](../corefp) | Optics, Semigroup/Monoid, standard-library extensions |
| [CoreFPOperators](../corefpoperators) | Operator syntax for `CoreFP` |
| [DataStructureOperators](../datastructureoperators) | Operator syntax for this module |

## Topics

### Error Handling & Sum Types
- ``Either``
- ``Validation``
- ``These``

### Collections & Sequences
- ``NonEmpty``
- ``Zipper``
- ``IdentifiedArray``
- ``IdentifiedArrayOf``

### Effects & State
- ``Reader``
- ``Writer``
- ``Stateful``
- ``Loading``

### Foundations
- ``Newtype``
- ``Gen``
- ``SplitMix64``
- ``AnyRandomNumberGenerator``

### Transformer Stack Inner Shapes
- ``EitherLike``
- ``NonEmptyLike``
- ``WriterLike``
- ``ValidationLike``
- ``ReaderLike``
- ``StatefulLike``

### Transformer Stacks (outer Array)
- ``ArrayTEither``
- ``ArrayTStateful``
- ``ArrayTWriter``

### Transformer Stacks (outer AsyncStream)
- ``AsyncStreamTEither``
- ``AsyncStreamTStateful``
- ``AsyncStreamTWriter``

### Transformer Stacks (outer Either)
- ``EitherTArray``
- ``EitherTNonEmpty``
- ``EitherTOptional``
- ``EitherTResult``
- ``EitherTStateful``
- ``EitherTValidation``
- ``EitherTWriter``

### Transformer Stacks (outer NonEmpty)
- ``NonEmptyTEither``
- ``NonEmptyTOptional``
- ``NonEmptyTResult``

### Transformer Stacks (outer Optional)
- ``OptionalTEither``
- ``OptionalTNonEmpty``
- ``OptionalTStateful``
- ``OptionalTWriter``

### Transformer Stacks (outer Publisher)
- ``PublisherTEither``
- ``PublisherTStateful``
- ``PublisherTWriter``

### Transformer Stacks (outer Reader)
- ``ReaderTArray``
- ``ReaderTAsyncStream``
- ``ReaderTEither``
- ``ReaderTNonEmpty``
- ``ReaderTOptional``
- ``ReaderTPublisher``
- ``ReaderTReader``
- ``ReaderTResult``
- ``ReaderTStateful``
- ``ReaderTValidation``
- ``ReaderTWriter``

### Transformer Stacks (outer Result)
- ``ResultTStateful``
- ``ResultTWriter``

### Transformer Stacks (outer Stateful)
- ``StatefulTArray``
- ``StatefulTAsyncStream``
- ``StatefulTEither``
- ``StatefulTNonEmpty``
- ``StatefulTOptional``
- ``StatefulTPublisher``
- ``StatefulTReader``
- ``StatefulTResult``
- ``StatefulTValidation``
- ``StatefulTWriter``

### Transformer Stacks (outer Validation)
- ``ValidationTArray``
- ``ValidationTEither``
- ``ValidationTNonEmpty``
- ``ValidationTOptional``
- ``ValidationTReader``
- ``ValidationTResult``
- ``ValidationTStateful``
- ``ValidationTWriter``

### Transformer Stacks (outer Writer)
- ``WriterTArray``
- ``WriterTAsyncStream``
- ``WriterTEither``
- ``WriterTNonEmpty``
- ``WriterTOptional``
- ``WriterTPublisher``
- ``WriterTReader``
- ``WriterTResult``
- ``WriterTStateful``
- ``WriterTValidation``
