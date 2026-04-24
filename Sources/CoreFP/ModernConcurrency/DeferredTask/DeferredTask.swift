// DeferredTask<Success>: a lazy IO-like computation that runs only when .run() is called.
// Nothing executes until run() — analogous to Haskell's IO monad or Scala's cats-effect IO.

public struct DeferredTask<Success: Sendable>: Sendable {
    let body: @Sendable () async -> Success

    public init(_ body: @escaping @Sendable () async -> Success) {
        self.body = body
    }

    public static func catching<S, E: Error>(_ body: @escaping @Sendable () async throws(E) -> S) -> DeferredTask<Result<S, E>> {
        .init {
            do throws(E) {
                return Result<S, E>.success(try await body())
            } catch {
                return Result<S, E>.failure(error)
            }
        }
    }

    /// Execute the deferred computation.
    public func run() async -> Success { await body() }

    /// Wrap in a Task for fire-and-forget or structured concurrency contexts.
    public func eraseToTask() -> Task<Success, Never> { Task { await body() } }

    /// Wrap in a Task for fire-and-forget or structured concurrency contexts.
    public func eraseToThrowingTask<S, E: Error>() -> Task<S, any Error> where Success == Result<S, E> {
        Task {
            try await body().get()
        }
    }
}
