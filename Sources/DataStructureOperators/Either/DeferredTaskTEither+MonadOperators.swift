import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: DeferredTask<Either<l,a>> -> (a -> DeferredTask<Either<l,b>>) -> DeferredTask<Either<l,b>>
public func >>- <L: Sendable, A: Sendable, B: Sendable>(
    _ task: DeferredTask<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<Either<L, B>>
) -> DeferredTask<Either<L, B>> {
    flatMapTDeferredTaskEither(task, fn)
}

// (-<<) :: (a -> DeferredTask<Either<l,b>>) -> DeferredTask<Either<l,a>> -> DeferredTask<Either<l,b>>
public func -<< <L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<Either<L, B>>,
    _ task: DeferredTask<Either<L, A>>
) -> DeferredTask<Either<L, B>> {
    task >>- fn
}
