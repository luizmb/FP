// SPDX-License-Identifier: Apache-2.0
@_exported import CoreFP

/// Generates a total `Iso` between a struct and a structural representation of its stored fields.
///
/// - `@Iso` on a struct → `static var iso: Iso<Self, FieldRepresentation>`, where the
///   representation is the field's type for a single-field struct, or a tuple of the field types
///   otherwise. Always sound — it round-trips through the struct's memberwise initialiser.
///
///   ```swift
///   @Iso struct Point { var x: Int; var y: Int }
///   // Point.iso : Iso<Point, (Int, Int)>
///
///   @Iso struct Celsius { var value: Double }
///   // Celsius.iso : Iso<Celsius, Double>
///   ```
///
/// - `@Iso(Other.self)` → `static var iso: Iso<Self, Other>`, mapping field-by-field through
///   `Other`'s memberwise initialiser. **Convenient but unverified**: the macro can't see
///   `Other`'s fields (only its name), so a shape mismatch surfaces as a compile error in the
///   generated code rather than a clean diagnostic.
///
/// For the library's generic `Newtype`, prefer its built-in `Newtype.iso`.
@attached(member, names: named(iso))
public macro Iso() = #externalMacro(module: "FPMacrosPlugin", type: "IsoMacro")

/// `@Iso(Other.self)` — see ``Iso()``.
@attached(member, names: named(iso))
public macro Iso<Other>(_ other: Other.Type) = #externalMacro(module: "FPMacrosPlugin", type: "IsoMacro")
