import CoreFP
import CoreFPOperators

// (>>-) :: DeferredTask<Result<a,e>> -> (a -> DeferredTask<Result<b,e>>) -> DeferredTask<Result<b,e>>
public func >>- <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ task: DeferredTask<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<Result<B, E>>
) -> DeferredTask<Result<B, E>> {
    flatMapTDeferredTaskResult(task, fn)
}

// (-<<) :: (a -> DeferredTask<Result<b,e>>) -> DeferredTask<Result<a,e>> -> DeferredTask<Result<b,e>>
public func -<< <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<Result<B, E>>,
    _ task: DeferredTask<Result<A, E>>
) -> DeferredTask<Result<B, E>> {
    task >>- fn
}
