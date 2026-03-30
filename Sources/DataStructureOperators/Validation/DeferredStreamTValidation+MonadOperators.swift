import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: DeferredStream<Validation<e,a>> -> (a -> DeferredStream<Validation<e,b>>) -> DeferredStream<Validation<e,b>>
public func >>- <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ stream: DeferredStream<Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<Validation<E, B>>
) -> DeferredStream<Validation<E, B>> {
    flatMapTDeferredStreamValidation(stream, fn)
}

// (-<<)
public func -<< <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<Validation<E, B>>,
    _ stream: DeferredStream<Validation<E, A>>
) -> DeferredStream<Validation<E, B>> {
    stream >>- fn
}
