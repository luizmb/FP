/// The FP umbrella module — re-exports all four sub-modules for single-import convenience.
///
/// Importing `FP` is equivalent to importing all four modules simultaneously:
///
/// ```swift
/// import FP
/// // is the same as:
/// // import CoreFP
/// // import CoreFPOperators
/// // import DataStructure
/// // import DataStructureOperators
/// ```
///
/// ## Module overview
///
/// | Module | Contents |
/// |--------|---------|
/// | `CoreFP` | Optics (Lens, Prism, AffineTraversal, Iso), Semigroup/Monoid hierarchy, DeferredStream, free functions, SumType protocol |
/// | `CoreFPOperators` | All operator definitions: `>>>`, `<<<`, `£`, `<|>`, `<£>`, `<*>`, `>>-`, `>=>`, `<=<`, etc. |
/// | `DataStructure` | Either, Reader, Writer, Stateful, Validation, NonEmpty |
/// | `DataStructureOperators` | Operator overloads for all DataStructure types |
///
/// ## Quick reference: core operators
///
/// | Operator | Haskell | Description |
/// |----------|---------|-------------|
/// | `>>>` | `>>>` / `.` | Left-to-right composition (functions and optics) |
/// | `<<<` | `.` / `<<<` | Right-to-left composition |
/// | `\|>` | (F# style) | Pipeline / flipped application |
/// | `£` | `$` | Low-precedence function application |
/// | `<£>` | `<$>` | Functor map |
/// | `<&>` | `<&>` | Flipped functor map |
/// | `<*>` | `<*>` | Applicative apply |
/// | `<>` | `<>` | Semigroup combine |
/// | `>>-` | `>>=` | Monadic bind |
/// | `>=>` | `>=>` | Kleisli composition |
/// | `<=<` | `<=<` | Reverse Kleisli composition |
/// | `<\|>` | `<\|>` | Alternative / fallback |
/// | `->>` | (comonad) | Comonad extend |
/// | `^` | (prefix) | KeyPath to Lens lift |
@_exported import CoreFP
@_exported import CoreFPOperators
@_exported import DataStructure
@_exported import DataStructureOperators
