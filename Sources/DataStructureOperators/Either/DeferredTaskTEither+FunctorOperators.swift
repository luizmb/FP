import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> DeferredTask<Either<l,a>> -> DeferredTask<Either<l,b>>
public func <£^> <L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<Either<L, A>>
) -> DeferredTask<Either<L, B>> {
    mapTDeferredTaskEither(fn, task)
}

// (<&^>) :: DeferredTask<Either<l,a>> -> (a -> b) -> DeferredTask<Either<l,b>>
public func <&^> <L: Sendable, A: Sendable, B: Sendable>(
    _ task: DeferredTask<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredTask<Either<L, B>> {
    mapTDeferredTaskEither(fn, task)
}
