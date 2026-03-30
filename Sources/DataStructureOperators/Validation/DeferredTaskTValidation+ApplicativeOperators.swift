import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: DeferredTask<Validation<e,a->b>> -> DeferredTask<Validation<e,a>> -> DeferredTask<Validation<e,b>>
public func <*> <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fns: DeferredTask<Validation<E, @Sendable (A) -> B>>,
    _ values: DeferredTask<Validation<E, A>>
) -> DeferredTask<Validation<E, B>> {
    applyTDeferredTaskValidation(fns, values)
}
