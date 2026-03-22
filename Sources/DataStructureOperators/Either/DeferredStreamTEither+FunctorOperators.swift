import DataStructure
import CoreFP
import CoreFPOperators

// (<£>) :: (a -> b) -> DeferredStream<Either<l,a>> -> DeferredStream<Either<l,b>>
public func <£> <L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<Either<L, A>>
) -> DeferredStream<Either<L, B>> {
    mapTDeferredStreamEither(fn, stream)
}

// (<&>) :: DeferredStream<Either<l,a>> -> (a -> b) -> DeferredStream<Either<l,b>>
public func <&> <L: Sendable, A: Sendable, B: Sendable>(
    _ stream: DeferredStream<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredStream<Either<L, B>> {
    mapTDeferredStreamEither(fn, stream)
}
