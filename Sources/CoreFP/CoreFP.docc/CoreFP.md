# ``CoreFP``

Optics, the Semigroup/Monoid hierarchy, standard-library extensions, and the point-free function utilities this whole library is built on.

## Overview

`CoreFP` extends the Swift standard library and Apple frameworks (`Optional`, `Result`, `Array`, `Combine.Publisher`, `AsyncSequence`, SwiftUI's `Binding`) with Functor/Applicative/Monad operations, and adds its own foundational types: the optics family (`Lens`, `Prism`, `Iso`, `AffineTraversal`), the `Semigroup`/`Monoid` hierarchy and its wrapper types (`Endo`, `EndoMut`, `Min`, `Max`, `First`, `Last`, `Dual`, `Ordering`), and the `SumType2` protocol. `Publisher` and `AsyncStream` follow Haskell stream semantics: bind is ordered concat, `<*>` is `ap` (cartesian), and `zip` is a separate named function. The library's own algebraic types (`Either`, `Validation`, `Reader`, `Newtype`, `Gen`, etc.) live in [DataStructure](../datastructure).

This module has no dependencies beyond the Swift standard library and (optionally) Combine/SwiftUI — everything here works on Linux, Windows, and Android too, guarded by `#if canImport(...)` where a symbol is Apple-only (`Combine.Publisher`, SwiftUI's `Binding`).

```swift
import CoreFP
import CoreFPOperators

struct Address: Sendable { var city: String }
struct Person: Sendable { var age: Int }
struct User: Sendable { var address: Address }

// Optional already gets Functor/Applicative/Monad from CoreFP:
let doubled = Optional(5).map { $0 * 2 }        // Optional(10)

// A lens from a key path, using the CoreFP named function:
let ageLens: Lens<Person, Int> = lens(\Person.age)

// Optics compose with >>> from CoreFPOperators:
let cityLens = lens(\User.address) >>> lens(\Address.city)
```

Monad-transformer stacks are structs named `OuterTInner` conforming to `TransformerStack` (or `MonadT` when the stack is a lawful monad). The ones made only of `CoreFP` types (`OptionalTArray`, `ArrayTResult`, `PublisherTOptional`, `AsyncStreamTResult`, …) live here, the rest in [DataStructure](../datastructure); see [MonadTransformers](../fp/monadtransformers).

Import [CoreFPOperators](../corefpoperators) alongside this module for the operator syntax (`<£>`, `<*>`, `>>-`, `>>>`, …) — the full precedence table is in [OperatorVocabulary](../fp/operatorvocabulary).

## Related Modules

| Module | Contents |
|--------|----------|
| [FP (umbrella)](../fp) | Re-exports all four modules; also the home of cross-cutting conceptual articles |
| [CoreFPOperators](../corefpoperators) | Operator syntax for this module |
| [DataStructure](../datastructure) | The library's own algebraic and effect types |
| [DataStructureOperators](../datastructureoperators) | Operator syntax for `DataStructure` |

## Topics

### Lenses, Prisms & Isos
- <doc:Optics>
- ``Lens``
- ``Prism``
- ``Iso``
- ``AffineTraversal``
- ``Traversal``

### Algebra
- <doc:SemigroupMonoid>
- ``Semigroup``
- ``Monoid``
- ``Min``
- ``Max``
- ``First``
- ``Last``
- ``Dual``
- ``Ordering``
- ``Endo``
- ``EndoMut``

### Sum Types
- ``SumType2``

### Standard Library Extensions
- ``Swift/Optional``
- ``Swift/Result``
- ``Swift/Array``
- ``_Concurrency/AsyncSequence``
- ``Combine/Publisher``

### Monad Transformers
- ``TransformerStack``
- ``MonadT``
- ``ArrayLike``
- ``OptionalLike``
- ``ResultLike``
- ``AsyncStreamLike``
- ``ArrayTOptional``
- ``ArrayTResult``
- ``AsyncStreamTArray``
- ``AsyncStreamTOptional``
- ``AsyncStreamTResult``
- ``OptionalTArray``
- ``OptionalTResult``
- ``PublisherTArray``
- ``PublisherTOptional``
- ``PublisherTResult``

### SwiftUI Interop
- <doc:Binding>

### Point-Free Style
- <doc:PointFreeStyle>
