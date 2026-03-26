import DataStructure
import CoreFP
import CoreFPOperators

// MARK: - Transformer functor operators: NonEmpty<Result<A, E>>

// (<£^>) :: (A -> B) -> NonEmpty<Result<A, E>> -> NonEmpty<Result<B, E>>
public func <£^> <A, B, E>(
    _ fn: @escaping (A) -> B,
    _ ne: NonEmpty<Result<A, E>>
) -> NonEmpty<Result<B, E>> {
    ne.mapT(fn)
}

// (<&^>) :: NonEmpty<Result<A, E>> -> (A -> B) -> NonEmpty<Result<B, E>>
public func <&^> <A, B, E>(
    _ ne: NonEmpty<Result<A, E>>,
    _ fn: @escaping (A) -> B
) -> NonEmpty<Result<B, E>> {
    ne.mapT(fn)
}
