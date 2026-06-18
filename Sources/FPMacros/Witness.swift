// SPDX-License-Identifier: Apache-2.0
@_exported import CoreFP

/// Generates a **witness** struct for a protocol — its requirements as `@Sendable` closure
/// fields and nothing else — so a conforming instance becomes a first-class, composable value.
///
/// A witness is the functional counterpart to a protocol existential: instead of `any P`, you
/// hold a `PWitness` value whose fields are the protocol's methods (as closures) and properties
/// (as thunks). This is the building block for dependency injection — you can construct, stub,
/// and compose witnesses as plain values.
///
/// ```swift
/// @Witness
/// public protocol Repository<Item> {
///     associatedtype Item
///     associatedtype Failure: Error
///     func fetch(id: String) async -> Result<Item, Failure>
///     func all() -> [Item]
///     var count: Int { get }
/// }
/// ```
/// expands to:
/// ```swift
/// public struct RepositoryWitness<Item, Failure: Error>: Sendable {
///     public var fetch: @Sendable (String) async -> Result<Item, Failure>
///     public var all: @Sendable () -> [Item]
///     public var count: @Sendable () -> Int
///     public init(fetch: ..., all: ..., count: ...) { ... }      // memberwise
///     public init<Base: Repository & Sendable>(_ instance: Base)  // from a conforming instance
///         where Base.Item == Item, Base.Failure == Failure { ... }
/// }
/// public extension Repository where Self: Sendable {
///     var witness: RepositoryWitness<Item, Failure> { .init(self) }
/// }
/// ```
///
/// ## What it handles
///
/// - **Methods** → `@Sendable` closure fields; `async`/`throws`/argument labels are preserved.
/// - **Get-only properties** → `@Sendable () -> T` thunks (never a stored value — *closures only*).
/// - **`{ get set }` properties** → a getter thunk (`x`) plus a `setX: @Sendable (T) -> Void`
///   closure. Because the protocol's setter is `mutating`, the *from-instance* `init` and the
///   `.witness` convenience are gated to `where …: AnyObject` whenever a settable member exists —
///   a reference conformer's `.witness` writes through the live instance; value-type conformers
///   build the witness via the memberwise init.
/// - **Associated types / primary generics** → generic parameters of the witness struct, with
///   their constraints; the from-instance init binds them via a `where` clause.
/// - **Overloads** (same base name) → disambiguated by argument labels, *only on collision*
///   (`fetch(id:)` + `fetch(name:)` → `fetchWithId` / `fetchWithName`).
/// - **Protocol inheritance** → composed by name: `ChildWitness` gains a `parent: ParentWitness`
///   field. The parent protocol must also be `@Witness` (the macro can only see its name).
/// - **Generic methods** → each generic parameter is lowered to its existential constraint when
///   that is sound (constrained, and not in the return type); otherwise the macro emits a
///   diagnostic and aborts.
///
/// `mutating`, `static`, and `init`/`subscript` requirements, and generic parameters that can't
/// be erased, are rejected with a diagnostic.
@attached(peer, names: suffixed(Witness))
@attached(extension, names: named(witness))
public macro Witness() = #externalMacro(module: "FPMacrosPlugin", type: "WitnessMacro")
