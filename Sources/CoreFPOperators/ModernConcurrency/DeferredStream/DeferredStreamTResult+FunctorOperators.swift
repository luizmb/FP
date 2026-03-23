import CoreFP
import CoreFPOperators

// (<£^>) :: (a -> b) -> DeferredStream<Result<a,e>> -> DeferredStream<Result<b,e>>
public func <£^> <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<Result<A, E>>
) -> DeferredStream<Result<B, E>> {
    mapTDeferredStreamResult(fn, stream)
}

// (<&^>) :: DeferredStream<Result<a,e>> -> (a -> b) -> DeferredStream<Result<b,e>>
public func <&^> <A: Sendable, B: Sendable, E: Error & Sendable>(
    _ stream: DeferredStream<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredStream<Result<B, E>> {
    mapTDeferredStreamResult(fn, stream)
}
