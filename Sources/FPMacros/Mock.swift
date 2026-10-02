// SPDX-License-Identifier: Apache-2.0
@_exported import CoreFP

/// Generates a configurable test mock for a protocol, wrapped in `#if DEBUG`.
///
/// `@Mock` emits a `struct <Protocol>Mock: <Protocol>` whose every requirement is backed by a
/// stored `wrapped…` closure. The memberwise init lets a test override just the requirements it
/// cares about; the rest default to a closure that calls ``fail(_:file:line:)``, which crashes
/// loudly the moment an un-overridden requirement is called.
///
/// ```swift
/// @Mock
/// protocol Service {
///     func fetch(id: String) -> AnyPublisher<[Item], any Error>
///     var isReady: Bool { get }
/// }
/// ```
/// expands (behind `#if DEBUG`) to:
/// ```swift
/// struct ServiceMock: Service {
///     var wrappedFetch: (String) -> AnyPublisher<[Item], any Error>
///     var wrappedIsReady: () -> Bool
///     init(
///         // each default is a closure literal that ignores its arguments and calls `fail(...)`
///         fetch: @escaping (String) -> AnyPublisher<[Item], any Error> = { … },
///         isReady: @escaping () -> Bool = { CoreFP.fail("Mock function not implemented for test case")() }
///     ) { self.wrappedFetch = fetch; self.wrappedIsReady = isReady }
///     func fetch(id: String) -> AnyPublisher<[Item], any Error> { wrappedFetch(id) }
///     var isReady: Bool { wrappedIsReady() }
/// }
/// ```
///
/// ## What it handles
///
/// - **Methods** → a `wrapped<Name>` closure + a delegating conforming method; `async`, `throws`,
///   typed `throws(E)` and labels are preserved. A `rethrows` requirement gets a `throws` closure
///   (the mock should only throw when the argument closure does).
/// - **Parameters** → `inout` (forwarded with `&`), non-escaping and `@autoclosure` closures
///   (the stored closure receives the autoclosure; call it to evaluate), variadics (the closure
///   receives an array), and unnamed `_:` parameters (given internal names).
/// - **Get-only properties** → a `wrapped<Name>` thunk + a computed property, including
///   `{ get async throws }` getters.
/// - **`{ get set }` properties** → `wrapped<Name>` + `wrapped<Name>Set` closures.
/// - **Associated types** → generic parameters of the mock struct.
/// - **Overloads** → disambiguated only on collision: by argument labels (`findWithId`), then by
///   labels and parameter types (`findWithIdInt` / `findWithIdString`); overloads that differ only
///   in return type or effects are diagnosed.
/// - **Generic methods** → a generic parameter is lowered to its existential constraint when it is
///   constrained, absent from the return type, and the whole type of exactly one parameter; a
///   top-level `some P` parameter becomes `any P`. Anything else is diagnosed.
/// - **`AnyObject` protocols** → a `final class` mock. **`Sendable` protocols** → `@Sendable`
///   closures (immutable ones in a class mock, so it is checked-`Sendable`).
///
/// **Protocol inheritance is not supported** (beyond `Sendable` / `AnyObject`) — the macro can't
/// see a parent protocol's requirements to synthesise them, and the mock must conform to all of
/// them. `mutating`, `static`, `init`, and `subscript` requirements, non-erasable generics, and
/// `private` protocols (use `fileprivate`) are diagnosed.
@attached(peer, names: suffixed(Mock))
public macro Mock() = #externalMacro(module: "FPMacrosPlugin", type: "MockMacro")
