// DeferredTaskTResult: outer = DeferredTask, inner = Result
// Type: DeferredTask<Result<A, E>>  — Haskell: ExceptT e DeferredTask

public func mapTDeferredTaskResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<Result<A, E>>
) -> DeferredTask<Result<B, E>> {
    task.map { result in result.map(fn) }
}

public func fmapTDeferredTaskResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredTask<Result<A, E>>) -> DeferredTask<Result<B, E>> {
    { @Sendable task in mapTDeferredTaskResult(fn, task) }
}
