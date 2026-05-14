import CoreFP

// ZIO<Env, Success, Failure>: the three-layer monad stack
//   ReaderT Env (ExceptT Failure DeferredTask) Success
//   ≅ Env -> DeferredTask<Result<Success, Failure>>
//
// Generic parameter order mirrors Result<Success, Failure> and Swift convention:
//   Env     — required environment / dependencies
//   Success — the value produced on the happy path
//   Failure — the typed error

/// An effect type that combines dependency injection, error handling, and deferred async execution.
///
/// `ZIO<Env, Success, Failure>` is the three-layer monad stack:
///
/// ```
/// ZIO<Env, Success, Failure>
///   ≅ ReaderT<Env, ExceptT<Failure, DeferredTask<_>>, Success>
///   ≅ (Env) -> DeferredTask<Result<Success, Failure>>
/// ```
///
/// It combines:
/// 1. **Reader monad**: dependency injection via `Env` — no work is done until a concrete
///    environment is provided.
/// 2. **Error handling**: typed errors via `Failure: Error` — the `Result<Success, Failure>`
///    channel is threaded through all `flatMap` compositions.
/// 3. **Deferred execution**: the underlying computation is a ``DeferredTask`` — nothing
///    runs until ``provide(_:)`` is called and the task is awaited.
///
/// This design mirrors Scala's ZIO / Haskell's `ReaderT + ExceptT + IO` pattern.
///
/// ## Generic parameter order
///
/// The parameter order mirrors `Result<Success, Failure>` and Swift convention:
/// - `Env` — the required environment / dependencies
/// - `Success` — the value produced on the happy path
/// - `Failure` — the typed error (must conform to `Error & Sendable`)
///
/// ## Creating a ZIO
///
/// ```swift
/// struct AppEnv { let db: Database }
///
/// let fetchUser: ZIO<AppEnv, User, DBError> = ZIO { env in
///     DeferredTask { try await env.db.getUser() }  // oversimplified
/// }
///
/// // Lift a pure value:
/// let pure: ZIO<AppEnv, Int, Never> = ZIO.pure(42)
///
/// // Read from the environment:
/// let db: ZIO<AppEnv, Database, Never> = ZIO.asks(\.db)
/// ```
///
/// ## Running a ZIO
///
/// ```swift
/// let task: DeferredTask<Result<User, DBError>> = fetchUser.provide(myEnv)
/// let result: Result<User, DBError> = await task.run()
/// ```
///
/// ## Functor / Applicative / Monad
///
/// ```swift
/// let name: ZIO<AppEnv, String, DBError> = fetchUser.map(\.name)
///
/// let profile: ZIO<AppEnv, Profile, DBError> = fetchUser.flatMap { user in
///     ZIO { env in DeferredTask { await env.db.getProfile(for: user) } }
/// }
/// ```
///
/// ## Kleisli composition
///
/// ```swift
/// let pipeline: (UserID) -> ZIO<AppEnv, Profile, DBError> =
///     getUser >=> enrichProfile   // using >=> from DataStructureOperators
/// ```
///
/// ## Error handling
///
/// ```swift
/// let recovered: ZIO<AppEnv, User, Never> = fetchUser.flatMapError { error in
///     ZIO { _ in .pure(.success(User.default)) }
/// }
/// ```
///
/// - SeeAlso: ``ZIOKleisli``, ``DeferredTask``, ``Reader``
public struct ZIO<Env: Sendable, Success: Sendable, Failure: Error & Sendable>: Sendable {
    /// The underlying function from `Env` to a deferred `Result`.
    public let run: @Sendable (Env) -> DeferredTask<Result<Success, Failure>>

    public init(_ run: @escaping @Sendable (Env) -> DeferredTask<Result<Success, Failure>>) {
        self.run = run
    }

    /// Provide the environment and obtain the underlying deferred task.
    public func callAsFunction(_ env: Env) -> DeferredTask<Result<Success, Failure>> {
        run(env)
    }

    /// Fully execute: supply environment, run the task, return the result.
    public func provide(_ env: Env) -> DeferredTask<Result<Success, Failure>> {
        run(env)
    }
}
