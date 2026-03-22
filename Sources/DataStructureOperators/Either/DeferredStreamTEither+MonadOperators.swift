import DataStructure
import CoreFP
import CoreFPOperators

// (>>-) :: DeferredStream<Either<l,a>> -> (a -> DeferredStream<Either<l,b>>) -> DeferredStream<Either<l,b>>
public func >>- <L: Sendable, A: Sendable, B: Sendable>(
    _ stream: DeferredStream<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<Either<L, B>>
) -> DeferredStream<Either<L, B>> {
    flatMapTDeferredStreamEither(stream, fn)
}

// (-<<) :: (a -> DeferredStream<Either<l,b>>) -> DeferredStream<Either<l,a>> -> DeferredStream<Either<l,b>>
public func -<< <L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<Either<L, B>>,
    _ stream: DeferredStream<Either<L, A>>
) -> DeferredStream<Either<L, B>> {
    stream >>- fn
}
