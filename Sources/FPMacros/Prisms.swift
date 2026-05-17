/// Generates an `enum prism` namespace, per-case computed optional properties, a `cases`
/// enumeration of case names, and an `is(_:)` helper for an enum.
///
/// For each case of the annotated enum the macro produces:
/// - `MyEnum.prism.caseName` → `Prism<MyEnum, AssociatedValue>` (static optic)
/// - `myEnum.caseName` → `AssociatedValue?` (computed property)
///
/// In addition it produces, for the enum as a whole:
/// - `MyEnum.cases` — a nested `CaseIterable` enum whose cases mirror the case *names* of
///   the annotated enum (no associated values), suitable for iteration, lookup tables, or
///   driving UI lists.
/// - `MyEnum.cases.matches(_:)` — returns `true` when a `cases` value names the same case
///   as a given `MyEnum` value, regardless of any associated payload.
/// - `myEnum.is(_:)` — flipped sugar for `cases.matches(self)`.
///
/// ```swift
/// @Prisms
/// enum Shape {
///     case circle(Double)
///     case rectangle(Double, Double)
///     case empty
/// }
///
/// let s = Shape.circle(3.14)
/// s.circle                               // Optional(3.14)
/// s.rectangle                            // nil
/// Shape.prism.circle.set(s, 5.0)         // Shape.circle(5.0)
/// Shape.prism.circle.over({ $0 * 2 })(s) // Shape.circle(6.28)
///
/// s.is(.circle)                          // true
/// s.is(.rectangle)                       // false
/// Shape.cases.allCases                   // [.circle, .rectangle, .empty]
/// ```
@attached(member, names: arbitrary)
public macro Prisms() =
    #externalMacro(module: "FPMacrosPlugin", type: "PrismsMacro")
