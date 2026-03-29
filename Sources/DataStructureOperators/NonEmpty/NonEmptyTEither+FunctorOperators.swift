import CoreFP
import CoreFPOperators
import DataStructure

// MARK: - Transformer functor operators: NonEmpty<Either<L, A>>

// (<£^>) :: (A -> B) -> NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>>
public func <£^> <L, A, B>(
    _ fn: @escaping (A) -> B,
    _ ne: NonEmpty<Either<L, A>>
) -> NonEmpty<Either<L, B>> {
    ne.mapT(fn)
}

// (<&^>) :: NonEmpty<Either<L, A>> -> (A -> B) -> NonEmpty<Either<L, B>>
public func <&^> <L, A, B>(
    _ ne: NonEmpty<Either<L, A>>,
    _ fn: @escaping (A) -> B
) -> NonEmpty<Either<L, B>> {
    ne.mapT(fn)
}
