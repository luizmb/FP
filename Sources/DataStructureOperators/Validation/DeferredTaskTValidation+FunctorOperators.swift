import DataStructure
import CoreFP
import CoreFPOperators

// (<£^>) :: (a -> b) -> DeferredTask<Validation<e,a>> -> DeferredTask<Validation<e,b>>
public func <£^> <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<Validation<E, A>>
) -> DeferredTask<Validation<E, B>> {
    mapTDeferredTaskValidation(fn, task)
}

// (<&^>) :: DeferredTask<Validation<e,a>> -> (a -> b) -> DeferredTask<Validation<e,b>>
public func <&^> <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ task: DeferredTask<Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredTask<Validation<E, B>> {
    mapTDeferredTaskValidation(fn, task)
}
