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
/// - **Methods** → `@Sendable` closure fields; `async`, `throws`, typed `throws(E)` and argument
///   labels are preserved; `inout` and `@autoclosure` parameters are forwarded.
/// - **Get-only properties** → `@Sendable () -> T` thunks (never a stored value — *closures only*),
///   including `{ get async throws }` getters (`@Sendable () async throws -> T`).
/// - **`{ get set }` properties** → a getter thunk (`x`) plus a `setX: @Sendable (T) -> Void`
///   closure. Because the protocol's setter is `mutating`, the *from-instance* `init` and the
///   `.witness` convenience are gated to `where …: AnyObject` whenever a settable member exists —
///   a reference conformer's `.witness` writes through the live instance; value-type conformers
///   build the witness via the memberwise init.
/// - **Associated types / primary generics** → generic parameters of the witness struct, with
///   their constraints; the from-instance init binds them via a `where` clause.
/// - **Overloads** (same base name) → disambiguated *only on collision*, by argument labels
///   (`fetch(id:)` + `fetch(name:)` → `fetchWithId` / `fetchWithName`), then by labels and
///   parameter types (`find(id: Int)` + `find(id: String)` → `findWithIdInt` / `findWithIdString`).
///   Overloads that differ only in return type or effects are diagnosed.
/// - **Protocol inheritance** → composed by name: `ChildWitness` gains a `parent: ParentWitness`
///   field. The parent protocol must also be `@Witness` (the macro can only see its name).
///   Compositions (`Sendable & AnyObject`) are split; marker and stdlib parents (`Sendable`,
///   `AnyObject`, `Equatable`, `Hashable`, `Identifiable`, `Codable`, …) are satisfied by the
///   conformer and not composed; generic parents (`Collection<Int>`) and stdlib protocols with
///   associated types are diagnosed. A parent with `{ get set }` requirements needs a
///   reference-type conformer, so its child must be class-bound (`protocol Child: AnyObject, Parent`).
/// - **Generic methods** → a generic parameter is lowered to its existential constraint when that
///   is sound: constrained, absent from the return type, and the whole type of exactly one
///   parameter (so the existential can be opened back into it). A top-level `some P` parameter
///   becomes `any P`. Anything else is diagnosed.
///
/// `mutating`, `static`, `rethrows`, `init`/`subscript` requirements, requirements mentioning
/// `Self`, variadic parameters, generic parameters that can't be erased, and `private` protocols
/// (use `fileprivate`) are rejected with a diagnostic.
@attached(peer, names: suffixed(Witness))
@attached(extension, names: named(witness))
public macro Witness() = #externalMacro(module: "FPMacrosPlugin", type: "WitnessMacro")
