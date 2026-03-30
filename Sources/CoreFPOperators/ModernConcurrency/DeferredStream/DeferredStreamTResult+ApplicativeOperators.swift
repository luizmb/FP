import CoreFP

// (<*>) :: DeferredStream<Result<a->b,e>> -> DeferredStream<Result<a,e>> -> DeferredStream<Result<b,e>>
public func <*> <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fns: DeferredStream<Result<@Sendable (A) -> B, E>>,
    _ values: DeferredStream<Result<A, E>>
) -> DeferredStream<Result<B, E>> {
    applyTDeferredStreamResult(fns, values)
}
