import CoreFP

// DeferredTaskTEither: outer = DeferredTask, inner = Either
// Type: DeferredTask<Either<L, A>>

public func mapTDeferredTaskEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<Either<L, A>>
) -> DeferredTask<Either<L, B>> {
    task.map { either in either.mapRight(fn) }
}

public func fmapTDeferredTaskEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredTask<Either<L, A>>) -> DeferredTask<Either<L, B>> {
    { @Sendable task in mapTDeferredTaskEither(fn, task) }
}
