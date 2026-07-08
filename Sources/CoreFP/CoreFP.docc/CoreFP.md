# ``CoreFP``

Optics, the Semigroup/Monoid hierarchy, standard-library extensions, and the point-free function utilities this whole library is built on.

## Overview

`CoreFP` extends the Swift standard library and Apple frameworks (`Optional`, `Result`, `Array`, `Combine.Publisher`, `AsyncSequence`, SwiftUI's `Binding`) with Functor/Applicative/Monad operations, and adds its own foundational types: the optics family (`Lens`, `Prism`, `Iso`, `AffineTraversal`), the `Semigroup`/`Monoid` hierarchy and its wrapper types (`Endo`, `EndoMut`, `Min`, `Max`, `First`, `Last`, `Dual`, `Ordering`), and the `SumType2` protocol. The library's own algebraic types (`Either`, `Validation`, `Reader`, `Newtype`, `Gen`, etc.) live in the `DataStructure` module's documentation (use the module switcher in the sidebar).

This module has no dependencies beyond the Swift standard library and (optionally) Combine/SwiftUI — everything here works on Linux, Windows, and Android too, guarded by `#if canImport(...)` where a symbol is Apple-only (`Combine.Publisher`, SwiftUI's `Binding`).

```swift
import CoreFP

// Optional already gets Functor/Applicative/Monad from CoreFP:
let doubled = Optional(5).map { $0 * 2 }        // Optional(10)

// Optics compose with >>> from CoreFPOperators:
let ageLens: Lens<Person, Int> = ^\Person.age
```

Import `CoreFPOperators` alongside this module for the operator syntax (`<£>`, `<*>`, `>>-`, `>>>`, …) — the full precedence table is in the "OperatorVocabulary" article, in the `FP` module's documentation (use the module switcher in the sidebar).

## Topics

### Lenses, Prisms & Isos
- <doc:Optics>

### Algebra
- <doc:SemigroupMonoid>
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

### SwiftUI Interop
- <doc:Binding>

### Point-Free Style
- <doc:PointFreeStyle>
