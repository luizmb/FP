import CoreFP
import CoreFPOperators

// (<£>) :: (a -> b) -> DeferredTask<Result<a,e>> -> DeferredTask<Result<b,e>>
public func <£> <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<Result<A, E>>
) -> DeferredTask<Result<B, E>> {
    mapTDeferredTaskResult(fn, task)
}

// (<&>) :: DeferredTask<Result<a,e>> -> (a -> b) -> DeferredTask<Result<b,e>>
public func <&> <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ task: DeferredTask<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredTask<Result<B, E>> {
    mapTDeferredTaskResult(fn, task)
}
