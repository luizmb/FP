import CoreFP
import DataStructure
import CoreFPOperators

// (<£^>) :: (a -> b) -> DeferredStream<Validation<e,a>> -> DeferredStream<Validation<e,b>>
public func <£^> <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<Validation<E, A>>
) -> DeferredStream<Validation<E, B>> {
    mapTDeferredStreamValidation(fn, stream)
}

// (<&^>) :: DeferredStream<Validation<e,a>> -> (a -> b) -> DeferredStream<Validation<e,b>>
public func <&^> <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ stream: DeferredStream<Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredStream<Validation<E, B>> {
    mapTDeferredStreamValidation(fn, stream)
}
