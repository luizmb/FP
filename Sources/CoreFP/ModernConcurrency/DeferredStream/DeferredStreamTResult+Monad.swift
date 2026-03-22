// DeferredStreamTResult: outer = DeferredStream, inner = Result
// Type: DeferredStream<Result<A, E>>

// flatMapT :: DeferredStream<Result<A,E>> -> (A -> DeferredStream<Result<B,E>>) -> DeferredStream<Result<B,E>>
// failure short-circuits (emits failure); success elements proceed through fn
public func flatMapTDeferredStreamResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ stream: DeferredStream<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<Result<B, E>>
) -> DeferredStream<Result<B, E>> {
    let s = stream
    return DeferredStream<Result<B, E>> {
        AsyncStream<Result<B, E>> { continuation in
            let task = Task { @Sendable in
                for await ra in s {
                    switch ra {
                    case let .success(a):
                        for await rb in fn(a) {
                            continuation.yield(rb)
                        }
                    case let .failure(e):
                        continuation.yield(.failure(e))
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

public func bindTDeferredStreamResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<Result<B, E>>
) -> @Sendable (DeferredStream<Result<A, E>>) -> DeferredStream<Result<B, E>> {
    { @Sendable stream in flatMapTDeferredStreamResult(stream, fn) }
}
