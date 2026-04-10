import CoreFP

// DeferredTaskTValidation: outer = DeferredTask, inner = Validation
// Type: DeferredTask<Validation<E, A>>

public func mapTDeferredTaskValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<Validation<E, A>>
) -> DeferredTask<Validation<E, B>> {
    task.map { v in v.mapSuccess(fn) }
}

public func fmapTDeferredTaskValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredTask<Validation<E, A>>) -> DeferredTask<Validation<E, B>> {
    { @Sendable task in mapTDeferredTaskValidation(fn, task) }
}
