import CoreFP
import CoreFPOperators

// (>>-) :: DeferredStream<a?> -> (a -> DeferredStream<b?>) -> DeferredStream<b?>
public func >>- <A: Sendable, B: Sendable>(
    _ stream: DeferredStream<A?>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<B?>
) -> DeferredStream<B?> {
    flatMapTDeferredStreamOptional(stream, fn)
}

// (-<<) :: (a -> DeferredStream<b?>) -> DeferredStream<a?> -> DeferredStream<b?>
public func -<< <A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<B?>,
    _ stream: DeferredStream<A?>
) -> DeferredStream<B?> {
    stream >>- fn
}
