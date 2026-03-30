import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: DeferredTask<Validation<e,a>> -> (a -> DeferredTask<Validation<e,b>>) -> DeferredTask<Validation<e,b>>
public func >>- <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ task: DeferredTask<Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<Validation<E, B>>
) -> DeferredTask<Validation<E, B>> {
    flatMapTDeferredTaskValidation(task, fn)
}

// (-<<)
public func -<< <E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<Validation<E, B>>,
    _ task: DeferredTask<Validation<E, A>>
) -> DeferredTask<Validation<E, B>> {
    task >>- fn
}
