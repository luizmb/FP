// SPDX-License-Identifier: Apache-2.0
@_exported import CoreFP

/// Applies optics uniformly — `@Lenses` to structs, `@Prisms` to enums — and, with `recursively: true`,
/// to **every nested struct and enum at any depth**, so an entire state tree gains composable optics from
/// a single annotation.
///
/// ```swift
/// @ApplyOptics(recursively: true)
/// struct Something {
///     struct Another { struct Hey { var x = 0 }; enum AAA { case a(Int) } }
///     enum BBB { case b(Int); struct Ho { var y = 0 } }
/// }
/// // Something.lens.…, Something.Another.Hey.lens.x, Something.Another.AAA.prism.a,
/// // Something.BBB.prism.b, Something.BBB.Ho.lens.y — all generated.
/// ```
///
/// Every level's optics are generated in that type's own body (like hand-writing `@Lenses`/`@Prisms`),
/// so memberwise inits and `let` properties work exactly as usual. A **caseless** namespace enum gets no
/// prisms (an empty namespace has no value) but is still recursed into.
///
/// ## Recursion & overrides
///
/// - **Single-node override:** put `@Lenses` / `@Prisms` on a nested type to customise just that node
///   (e.g. `@Lenses(init: .public)`); the recursion still flows past it into its descendants.
/// - **Re-root a subtree:** put another `@ApplyOptics(...)` on a nested type; its options govern it and
///   its descendants.
/// - **Cut a subtree:** put ``NoOptics()`` on a node; it and everything below get no optics.
///
/// Without `recursively` it's a kind-dispatched drop-in for `@Lenses`/`@Prisms` on the annotated type only.
///
/// - Parameters:
///   - emit: Which `@Lenses` pieces to emit on structs (`.all`, `.initOnly`, `.lensesOnly`).
///   - access: Access level of the generated memberwise `init` on structs (defaults to `.internal`).
///   - options: Which `@Prisms` pieces to emit on enums (`.all`, `.prisms`, `.cases`).
///   - recursively: When `true`, apply to every nested struct/enum at any depth.
@attached(member, names: arbitrary)
@attached(extension, conformances: Prismatic)
@attached(memberAttribute)
public macro ApplyOptics(
    _ emit: LensesEmit = .all,
    init access: LensesAccess = .internal,
    prisms options: PrismsOptions = .all,
    recursively: Bool = false
) = #externalMacro(module: "FPMacrosPlugin", type: "ApplyOpticsMacro")

/// Internal relay for ``ApplyOptics(_:init:prisms:recursively:)``'s recursion cycle. Do **not** write this
/// by hand — `@ApplyOptics` stamps it (and it stamps `@ApplyOptics` back) to recurse to arbitrary depth,
/// working around Swift's rule that a macro's `memberAttribute` role isn't re-run on attributes it added.
@attached(member, names: arbitrary)
@attached(extension, conformances: Prismatic)
@attached(memberAttribute)
public macro _ApplyOpticsRelay(
    _ emit: LensesEmit = .all,
    init access: LensesAccess = .internal,
    prisms options: PrismsOptions = .all,
    recursively: Bool = false
) = #externalMacro(module: "FPMacrosPlugin", type: "ApplyOpticsRelayMacro")

/// Marks a `struct` or `enum` so ``ApplyOptics(_:init:prisms:recursively:)`` **skips it and its whole
/// subtree** — no optics on the node, and the recursion does not descend into it. A pure marker.
@attached(peer)
public macro NoOptics() = #externalMacro(module: "FPMacrosPlugin", type: "NoOpticsMacro")
