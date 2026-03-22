import CoreFP
import CoreFPOperators

// (>>-) :: DeferredStream<Result<a,e>> -> (a -> DeferredStream<Result<b,e>>) -> DeferredStream<Result<b,e>>
public func >>- <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ stream: DeferredStream<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<Result<B, E>>
) -> DeferredStream<Result<B, E>> {
    flatMapTDeferredStreamResult(stream, fn)
}

// (-<<) :: (a -> DeferredStream<Result<b,e>>) -> DeferredStream<Result<a,e>> -> DeferredStream<Result<b,e>>
public func -<< <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<Result<B, E>>,
    _ stream: DeferredStream<Result<A, E>>
) -> DeferredStream<Result<B, E>> {
    stream >>- fn
}
