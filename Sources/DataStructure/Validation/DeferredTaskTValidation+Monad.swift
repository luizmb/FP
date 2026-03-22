import CoreFP

// DeferredTaskTValidation: outer = DeferredTask, inner = Validation
// Type: DeferredTask<Validation<E, A>>

// flatMapT: .failure short-circuits; .success(a) proceeds through fn
public func flatMapTDeferredTaskValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ task: DeferredTask<Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<Validation<E, B>>
) -> DeferredTask<Validation<E, B>> {
    task.flatMap { v in
        switch v {
        case let .success(a): fn(a)
        case let .failure(e): .pure(.failure(e))
        }
    }
}

public func bindTDeferredTaskValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<Validation<E, B>>
) -> @Sendable (DeferredTask<Validation<E, A>>) -> DeferredTask<Validation<E, B>> {
    { @Sendable task in flatMapTDeferredTaskValidation(task, fn) }
}
