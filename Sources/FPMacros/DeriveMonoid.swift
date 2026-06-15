@_exported import CoreFP

/// Derives `Semigroup` + `Monoid` for a struct as the **product** of its stored properties.
///
/// Every stored property must itself be a `Monoid`. The macro synthesises:
/// - `combine` — combines the two values field-by-field,
/// - `identity` — each field's `identity`.
///
/// ```swift
/// @DeriveMonoid
/// struct Stats {
///     var clicks: Int.Monoids.Sum
///     var ok: Bool.Monoids.And
/// }
/// // Stats.identity == Stats(clicks: .init(0), ok: .init(true))
/// // combine sums clicks and ANDs ok, field-wise.
/// ```
///
/// For a single-field struct this is exactly "forward to the wrapped value's Monoid". A bare
/// `Int` field won't work — `Int` has no canonical monoid; wrap it as `Int.Monoids.Sum` /
/// `Int.Monoids.Product`. Generic structs are supported by constraining every generic parameter
/// to `Monoid`. The struct must keep its (synthesised or written) memberwise initialiser.
@attached(extension, conformances: Monoid, names: named(combine), named(identity))
public macro DeriveMonoid() = #externalMacro(module: "FPMacrosPlugin", type: "DeriveMonoidMacro")
