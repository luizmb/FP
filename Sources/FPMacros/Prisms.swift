@_exported import CoreFP

/// Generates per-case optics, accessors, and a case-name mirror enum for an enum.
///
/// By default (`@Prisms` or `@Prisms(.all)`) the macro emits:
/// - `MyEnum.Prisms` — a `Sendable` struct holding one `Prism<MyEnum, AssociatedValue>`
///   per case as a stored property with a default value.
/// - `MyEnum.prism` — a `static let` (or `static var` for generic enums) returning the
///   `Prisms` instance. Access via `MyEnum.prism.caseName`.
/// - `myEnum.caseName` — per-case `AssociatedValue?` accessor. By default emitted as one
///   computed property per case. If you add `@dynamicMemberLookup` to the enum's
///   declaration, the macro collapses to a **single** subscript that handles every case
///   via key paths — same call site, lower code footprint.
/// - `MyEnum.cases` — a nested `CaseMatchable`/`CaseIterable` enum that mirrors the
///   case *names* (no associated payloads).
/// - `myEnum.is(.caseName)` — a per-enum predicate, delegating to `cases.matches`.
///
/// The `HasCases` protocol in `CoreFP` lets file-level types opt into a polymorphic
/// `is(_:)` via protocol extension — `@Prisms` doesn't add the conformance automatically
/// because Swift's extension-macro role can't reach into private/fileprivate nested
/// types. To opt in:
///
/// ```swift
/// extension MyEnum: HasCases { typealias Cases = cases }
/// ```
///
/// ## Slicing the output
///
/// Use `PrismsOptions` to opt out of pieces you don't need:
///
/// ```swift
/// @Prisms(.cases)                        // only the `cases` enum + is(_:)
/// @Prisms(.prisms)                       // only the `Prisms` struct + `static prism`
/// @Prisms([.prisms, .properties])        // optics + accessors, no cases / is
/// ```
///
/// `.properties` requires `.prisms` — silently auto-promoted if missing.
///
/// ## Dynamic member lookup
///
/// ```swift
/// @dynamicMemberLookup                      // ← opt-in: one subscript instead of N props
/// @Prisms
/// public enum Shape {
///     case circle(Double)
///     case rectangle(Double, Double)
/// }
///
/// let s: Shape = .circle(3.14)
/// s.circle                                  // Optional(3.14) — through the subscript
/// ```
///
/// If you request `.properties` (the default) without `@dynamicMemberLookup`, the macro
/// emits a *warning* suggesting the attribute and falls back to per-case computed
/// properties.
///
/// ## Access levels
///
/// `@Prisms` cannot be applied to `private` enums — it raises a compile-time error.
/// `private`'s type-scope semantics break the generated namespace. Use `fileprivate`
/// instead (functionally identical at file scope).
///
/// All other access levels (`fileprivate`, `internal`, `package`, `public`, `open`) work
/// uniformly. Nesting under another type is fine at any of those levels.
///
/// ## Example
///
/// ```swift
/// @dynamicMemberLookup
/// @Prisms
/// public enum Shape {
///     case circle(Double)
///     case rectangle(Double, Double)
///     case empty
/// }
///
/// let s = Shape.circle(3.14)
/// s.circle                               // Optional(3.14) — via dynamic lookup
/// s.rectangle                            // nil
/// Shape.prism.circle.set(s, 5.0)         // Shape.circle(5.0)
/// Shape.prism.circle.over({ $0 * 2 })(s) // Shape.circle(6.28)
///
/// s.is(.circle)                          // true
/// Shape.cases.allCases                   // [.circle, .rectangle, .empty]
/// ```
@attached(member, names: arbitrary)
public macro Prisms(_ options: PrismsOptions = .all) =
    #externalMacro(module: "FPMacrosPlugin", type: "PrismsMacro")

/// Granular controls for `@Prisms` output. `.all` is the default.
public struct PrismsOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Emit the `Prisms` struct and `static prism` accessor.
    public static let prisms = PrismsOptions(rawValue: 1 << 0)
    /// Emit per-case accessors — one computed property per case, OR a single
    /// `subscript(dynamicMember:)` if `@dynamicMemberLookup` is on the host.
    /// Requires `.prisms` — silently auto-promoted if missing.
    public static let properties = PrismsOptions(rawValue: 1 << 1)
    /// Emit the `MyEnum.cases` enum (conforming to `CaseMatchable` / `CaseIterable`)
    /// and a `myEnum.is(_:)` predicate.
    public static let cases = PrismsOptions(rawValue: 1 << 2)
    public static let all: PrismsOptions = [.prisms, .properties, .cases]
}
