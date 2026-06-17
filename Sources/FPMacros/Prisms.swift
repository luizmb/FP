@_exported import CoreFP

/// Generates per-case optics and a case-name mirror enum for an enum.
///
/// By default (`@Prisms` or `@Prisms(.all)`) the macro emits:
/// - `MyEnum.Prisms` — a `Sendable` struct holding one `Prism<MyEnum, AssociatedValue>`
///   per case as a stored property with a default value.
/// - `MyEnum.prism` — a `static let` (or `static var` for generic enums) returning the
///   `Prisms` instance. Access via `MyEnum.prism.caseName`.
/// - `Prismatic` conformance — which unlocks composable `\.case` key paths via `PrismFocus`:
///   `Prism(\.caseName)` recovers a concrete prism, and `\.a.b.c` composes through nested cases.
/// - `MyEnum.Cases` — a nested `CaseMatchable` (which inherits `CaseIterable`) enum
///   that mirrors the case *names* (no associated payloads).
/// - `myEnum.is(.caseName)` — a per-enum predicate, delegating to `cases.matches`.
///
/// To extract a case's payload, use the prism (`MyEnum.prism.caseName.preview(value)`), the
/// case key path (`Prism(\.caseName).preview(value)`), or plain `if case` pattern matching.
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
/// @Prisms(.cases)    // only the `Cases` enum + is(_:)
/// @Prisms(.prisms)   // only the `Prisms` struct + `static prism` + `Prismatic`
/// ```
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
/// @Prisms
/// public enum Shape {
///     case circle(Double)
///     case rectangle(Double, Double)
///     case empty
/// }
///
/// let s = Shape.circle(3.14)
/// Shape.prism.circle.preview(s)          // Optional(3.14)
/// Shape.prism.circle.set(s, 5.0)         // Shape.circle(5.0)
/// Shape.prism.circle.over({ $0 * 2 })(s) // Shape.circle(6.28)
/// Prism(\.circle).preview(s)             // Optional(3.14) — via the case key path
///
/// s.is(.circle)                          // true
/// Shape.Cases.allCases                   // [.circle, .rectangle, .empty]
/// ```
@attached(member, names: arbitrary)
@attached(extension, conformances: Prismatic)
public macro Prisms(_ options: PrismsOptions = .all) =
    #externalMacro(module: "FPMacrosPlugin", type: "PrismsMacro")

/// Granular controls for `@Prisms` output. `.all` is the default.
public struct PrismsOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Emit the `Prisms` struct, the `static prism` accessor, and `Prismatic` conformance.
    public static let prisms = PrismsOptions(rawValue: 1 << 0)
    /// Emit the `MyEnum.Cases` enum (conforming to `CaseMatchable`, which inherits
    /// `CaseIterable`) and a `myEnum.is(_:)` predicate.
    public static let cases = PrismsOptions(rawValue: 1 << 1)
    public static let all: PrismsOptions = [.prisms, .cases]
}
