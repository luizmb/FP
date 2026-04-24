import CoreFP

// ZIO<Env, Success, Failure>: the three-layer monad stack
//   ReaderT Env (ExceptT Failure DeferredTask) Success
//   ≅ Env -> DeferredTask<Result<Success, Failure>>
//
// Generic parameter order mirrors Result<Success, Failure> and Swift convention:
//   Env     — required environment / dependencies
//   Success — the value produced on the happy path
//   Failure — the typed error

public struct ZIO<Env: Sendable, Success: Sendable, Failure: Error & Sendable>: Sendable {
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
