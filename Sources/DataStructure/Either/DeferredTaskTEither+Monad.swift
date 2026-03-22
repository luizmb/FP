import CoreFP

// DeferredTaskTEither: outer = DeferredTask, inner = Either
// Type: DeferredTask<Either<L, A>>

// flatMapT: .left short-circuits; .right(a) proceeds through fn
public func flatMapTDeferredTaskEither<L: Sendable, A: Sendable, B: Sendable>(
    _ task: DeferredTask<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<Either<L, B>>
) -> DeferredTask<Either<L, B>> {
    task.flatMap { either in
        switch either {
        case let .right(a): fn(a)
        case let .left(l): .pure(.left(l))
        }
    }
}

public func bindTDeferredTaskEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<Either<L, B>>
) -> @Sendable (DeferredTask<Either<L, A>>) -> DeferredTask<Either<L, B>> {
    { @Sendable task in flatMapTDeferredTaskEither(task, fn) }
}
