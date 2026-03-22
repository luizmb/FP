import CoreFP
import CoreFPOperators

// (<*>) :: DeferredTask<Result<a->b,e>> -> DeferredTask<Result<a,e>> -> DeferredTask<Result<b,e>>
public func <*> <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fns: DeferredTask<Result<@Sendable (A) -> B, E>>,
    _ values: DeferredTask<Result<A, E>>
) -> DeferredTask<Result<B, E>> {
    applyTDeferredTaskResult(fns, values)
}
