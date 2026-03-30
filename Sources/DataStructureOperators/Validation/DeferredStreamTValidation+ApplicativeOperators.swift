import CoreFP
import DataStructure
import CoreFPOperators

// (<*>) :: DeferredStream<Validation<e,a->b>> -> DeferredStream<Validation<e,a>> -> DeferredStream<Validation<e,b>>
public func <*> <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fns: DeferredStream<Validation<E, @Sendable (A) -> B>>,
    _ values: DeferredStream<Validation<E, A>>
) -> DeferredStream<Validation<E, B>> {
    applyTDeferredStreamValidation(fns, values)
}
