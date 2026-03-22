// DeferredTaskTResult: outer = DeferredTask, inner = Result
// Type: DeferredTask<Result<A, E>>

// flatMapT :: DeferredTask<Result<A,E>> -> (A -> DeferredTask<Result<B,E>>) -> DeferredTask<Result<B,E>>
// failure short-circuits; success proceeds through fn
public func flatMapTDeferredTaskResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ task: DeferredTask<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<Result<B, E>>
) -> DeferredTask<Result<B, E>> {
    task.flatMap { result in
        switch result {
        case let .success(a): fn(a)
        case let .failure(e): .pure(.failure(e))
        }
    }
}

public func bindTDeferredTaskResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<Result<B, E>>
) -> @Sendable (DeferredTask<Result<A, E>>) -> DeferredTask<Result<B, E>> {
    { @Sendable task in flatMapTDeferredTaskResult(task, fn) }
}
