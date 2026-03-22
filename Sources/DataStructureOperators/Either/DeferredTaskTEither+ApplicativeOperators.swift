import DataStructure
import CoreFP
import CoreFPOperators

// (<*>) :: DeferredTask<Either<l,a->b>> -> DeferredTask<Either<l,a>> -> DeferredTask<Either<l,b>>
public func <*> <L: Sendable, A: Sendable, B: Sendable>(
    _ fns: DeferredTask<Either<L, @Sendable (A) -> B>>,
    _ values: DeferredTask<Either<L, A>>
) -> DeferredTask<Either<L, B>> {
    applyTDeferredTaskEither(fns, values)
}
