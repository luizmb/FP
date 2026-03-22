// DeferredTask<Success>: a lazy IO-like computation that runs only when .run() is called.
// Nothing executes until run() — analogous to Haskell's IO monad or Scala's cats-effect IO.

public struct DeferredTask<Success: Sendable>: Sendable {
    let body: @Sendable () async -> Success

    public init(_ body: @escaping @Sendable () async -> Success) {
        self.body = body
    }

    /// Execute the deferred computation.
    public func run() async -> Success { await body() }

    /// Wrap in a Task for fire-and-forget or structured concurrency contexts.
    public func eraseToTask() -> Task<Success, Never> { Task { await body() } }
}
