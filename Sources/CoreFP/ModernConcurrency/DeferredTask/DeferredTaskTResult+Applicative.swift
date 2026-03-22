// DeferredTaskTResult: outer = DeferredTask, inner = Result
// Type: DeferredTask<Result<A, E>>

public func liftA2TDeferredTaskResult<A: Sendable, B: Sendable, C: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredTask<Result<A, E>>, DeferredTask<Result<B, E>>) -> DeferredTask<Result<C, E>> {
    { @Sendable ta, tb in
        liftA2DeferredTask({ ra, rb -> Result<C, E> in
            switch (ra, rb) {
            case let (.success(a), .success(b)): .success(fn(a, b))
            case let (.failure(e), _): .failure(e)
            case let (_, .failure(e)): .failure(e)
            }
        })(ta, tb)
    }
}

public func applyTDeferredTaskResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fns: DeferredTask<Result<@Sendable (A) -> B, E>>,
    _ values: DeferredTask<Result<A, E>>
) -> DeferredTask<Result<B, E>> {
    liftA2DeferredTask({ rf, ra -> Result<B, E> in
        switch (rf, ra) {
        case let (.success(f), .success(a)): .success(f(a))
        case let (.failure(e), _): .failure(e)
        case let (_, .failure(e)): .failure(e)
        }
    })(fns, values)
}
