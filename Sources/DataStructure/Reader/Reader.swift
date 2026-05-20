import CoreFP
import Foundation

/// A computation that depends on a shared read-only environment.
///
/// `Reader<Environment, Output>` is the classic Reader monad. It wraps a function
/// `(Environment) -> Output` and provides a rich API for composing environment-dependent
/// computations without threading the environment through every function call manually.
///
/// ## When to use Reader
///
/// Use `Reader` when multiple functions all need access to the same configuration,
/// dependencies, or context object (the "environment"), and you want to compose those
/// functions in a point-free style without explicitly passing the environment everywhere.
///
/// ## Creating a Reader
///
/// ```swift
/// struct AppEnv { let db: Database; let logger: Logger }
///
/// let fetchUser: Reader<AppEnv, User> = Reader { env in
///     env.db.fetchUser()
/// }
///
/// // Or using the named constructor `asks`:
/// let getDB = Reader<AppEnv, Database>.asks(\.db)
/// ```
///
/// ## Running a Reader
///
/// ```swift
/// let user = fetchUser.runReader(myEnv)
/// // Or using callAsFunction:
/// let user = fetchUser(myEnv)
/// ```
///
/// ## Functor / Applicative / Monad
///
/// ```swift
/// let userName: Reader<AppEnv, String> = fetchUser.map(\.name)
///
/// let combined = fetchUser.flatMap { user in
///     Reader { env in env.db.fetchProfile(for: user) }
/// }
///
/// // ask returns the entire environment:
/// let env: Reader<AppEnv, AppEnv> = Reader.ask
///
/// // asks extracts a part of it:
/// let logger: Reader<AppEnv, Logger> = Reader.asks(\.logger)
/// ```
///
/// ## Contravariant functor on environment
///
/// `Reader` is also a contravariant functor on `Environment` via ``contramapEnvironment(_:)``,
/// which lets you widen a `Reader<LocalEnv, A>` into a `Reader<GlobalEnv, A>`:
///
/// ```swift
/// let localReader: Reader<UserService, String> = …
/// let globalReader: Reader<AppEnv, String> = localReader.contramapEnvironment(\.userService)
/// ```
///
/// ## Comonad (when Environment: Monoid)
///
/// When `Environment` is a ``Monoid``, `Reader` is also a `Comonad`:
/// - ``Reader/extract``: run the reader with the identity environment.
/// - ``Reader/extend(_:)``: shift the environment using `Monoid.combine`.
/// - ``Reader/duplicate``: the standard comonad duplication.
///
/// ## Operator forms
///
/// All monad/functor operations have operator forms in `DataStructureOperators`:
///
/// ```swift
/// fetchUser <&> \.name           // map
/// fetchUser >>- { … }            // flatMap / bind
/// fetchUser >=> enrichProfile    // Kleisli composition
/// ```
///
/// - SeeAlso: ``Writer``, ``Stateful``, ``ZIO``, ``FunctionWrapper``
public struct Reader<Environment, Output>: FunctionWrapper {
    /// The underlying function. Call this (or use `callAsFunction`) to run the reader.
    public let runReader: @Sendable (Environment) -> Output

    public init(_ fn: @escaping @Sendable (Environment) -> Output) {
        self.runReader = fn
    }

    /// Run the reader by applying `value` as the environment.
    public func callAsFunction(_ value: Environment) -> Output {
        runReader(value)
    }
}
