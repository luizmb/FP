@_exported import CoreFP

/// Generates a configurable test mock for a protocol, wrapped in `#if DEBUG`.
///
/// `@Mock` emits a `struct <Protocol>Mock: <Protocol>` whose every requirement is backed by a
/// stored `wrapped…` closure. The memberwise init lets a test override just the requirements it
/// cares about; the rest default to ``fail(_:file:line:)``, which crashes loudly the moment an
/// un-overridden requirement is called.
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
///         fetch: @escaping (String) -> AnyPublisher<[Item], any Error> = fail("Mock function not implemented for test case"),
///         isReady: @escaping () -> Bool = fail("Mock function not implemented for test case")
///     ) { self.wrappedFetch = fetch; self.wrappedIsReady = isReady }
///     func fetch(id: String) -> AnyPublisher<[Item], any Error> { wrappedFetch(id) }
///     var isReady: Bool { wrappedIsReady() }
/// }
/// ```
///
/// ## What it handles
///
/// - **Methods** → a `wrapped<Name>` closure + a delegating conforming method (`async`/`throws`/
///   labels preserved); `fail(...)` default.
/// - **Get-only properties** → a `wrapped<Name>` thunk + a computed property.
/// - **`{ get set }` properties** → `wrapped<Name>` + `wrapped<Name>Set` closures.
/// - **Associated types** → generic parameters of the mock struct.
/// - **Overloads** → disambiguated by argument labels only on collision.
/// - **Generic methods** → each generic parameter is lowered to its existential constraint when
///   sound (constrained, not in the return type); otherwise diagnosed.
///
/// **Protocol inheritance is not supported** — the macro can't see a parent protocol's
/// requirements to synthesise them, and the mock must conform to all of them. `mutating`,
/// `static`, `init`, and `subscript` requirements, and non-erasable generics, are diagnosed.
@attached(peer, names: suffixed(Mock))
public macro Mock() = #externalMacro(module: "FPMacrosPlugin", type: "MockMacro")
