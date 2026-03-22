// DeferredStreamTResult: outer = DeferredStream, inner = Result
// Type: DeferredStream<Result<A, E>>

public func liftA2TDeferredStreamResult<A: Sendable, B: Sendable, C: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredStream<Result<A, E>>, DeferredStream<Result<B, E>>) -> DeferredStream<Result<C, E>> {
    { @Sendable sa, sb in
        liftA2DeferredStream({ ra, rb -> Result<C, E> in
            switch (ra, rb) {
            case let (.success(a), .success(b)): .success(fn(a, b))
            case let (.failure(e), _): .failure(e)
            case let (_, .failure(e)): .failure(e)
            }
        })(sa, sb)
    }
}

public func applyTDeferredStreamResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fns: DeferredStream<Result<@Sendable (A) -> B, E>>,
    _ values: DeferredStream<Result<A, E>>
) -> DeferredStream<Result<B, E>> {
    liftA2DeferredStream({ rf, ra -> Result<B, E> in
        switch (rf, ra) {
        case let (.success(f), .success(a)): .success(f(a))
        case let (.failure(e), _): .failure(e)
        case let (_, .failure(e)): .failure(e)
        }
    })(fns, values)
}
