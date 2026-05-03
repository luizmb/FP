/// Generates an `enum prism` namespace and per-case computed optional properties for an enum.
///
/// For each case the macro produces:
/// - `MyEnum.prism.caseName` → `Prism<MyEnum, AssociatedValue>` (static optic)
/// - `myEnum.caseName` → `AssociatedValue?` (computed property)
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
/// ```
@attached(member, names: arbitrary)
public macro Prisms() =
    #externalMacro(module: "FPMacrosPlugin", type: "PrismsMacro")
