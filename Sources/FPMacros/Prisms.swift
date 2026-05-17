@_exported import CoreFP

/// Generates per-case optics, accessors, and a case-name mirror enum for an enum.
///
/// By default (`@Prisms` or `@Prisms(.all)`) the macro emits:
/// - `MyEnum.prism.caseName` — a `Prism<MyEnum, AssociatedValue>` per case, in a nested
///   `enum prism` namespace.
/// - `myEnum.caseName` — an `AssociatedValue?` computed property per case.
/// - `MyEnum.cases` — a nested `CaseMatchable`/`CaseIterable` enum that mirrors the
///   case *names* (no associated payloads).
/// - `myEnum.is(.caseName)` — a per-enum predicate, delegating to `cases.matches`.
///
/// The `HasCases` protocol in `CoreFP` lets file-level types opt into a polymorphic
/// `is(_:)` via protocol extension — `@Prisms` doesn't add the conformance automatically
/// because Swift's extension-macro role can't reach into private nested types. To opt in
/// for a public/internal type:
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
/// @Prisms(.prisms)                       // only the `prism` namespace
/// @Prisms([.prisms, .properties])        // optics + accessors, no cases / is
/// ```
///
/// `.properties` requires `.prisms` to also be emitted — the per-case computed
/// properties delegate to `Self.prism.caseName.preview(self)`. The macro auto-promotes
/// `.prisms` silently when `.properties` is requested.
///
/// ## Visibility
///
/// The generated `prism` struct, `cases` enum, and `HasCases` conformance mirror the
/// host enum's declared visibility. There is no visibility parameter — Swift enum cases
/// inherit the enum's visibility, so there is nothing to filter.
///
/// ## Example
///
/// ```swift
/// @Prisms
/// public enum Shape {
///     case circle(Double)
///     case rectangle(Double, Double)
///     case empty
/// }
///
/// let s = Shape.circle(3.14)
/// s.circle                               // Optional(3.14)        — via dynamic lookup
/// s.rectangle                            // nil
/// Shape.prism.circle.set(s, 5.0)         // Shape.circle(5.0)
/// Shape.prism.circle.over({ $0 * 2 })(s) // Shape.circle(6.28)
///
/// s.is(.circle)                          // true   (from HasCases extension)
/// Shape.cases.allCases                   // [.circle, .rectangle, .empty]
/// ```
@attached(member, names: arbitrary)
public macro Prisms(_ options: PrismsOptions = .all) =
    #externalMacro(module: "FPMacrosPlugin", type: "PrismsMacro")

/// Granular controls for `@Prisms` output. `.all` is the default.
public struct PrismsOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Emit the `MyEnum.prism` namespace with one `Prism` per case.
    public static let prisms     = PrismsOptions(rawValue: 1 << 0)
    /// Emit per-case computed properties (`myEnum.caseName` → `AssociatedValue?`).
    /// Requires `.prisms` — silently auto-promoted if missing.
    public static let properties = PrismsOptions(rawValue: 1 << 1)
    /// Emit the `MyEnum.cases` enum (conforming to `CaseMatchable` / `CaseIterable`)
    /// and a `myEnum.is(_:)` predicate.
    public static let cases      = PrismsOptions(rawValue: 1 << 2)
    public static let all: PrismsOptions = [.prisms, .properties, .cases]
}
