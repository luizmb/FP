import CoreFP
import CoreFPOperators
import DataStructure

// MARK: - Transformer functor operators: NonEmpty<A?> and NonEmpty<A>?

// (<£^>) :: (A -> B) -> NonEmpty<A?> -> NonEmpty<B?>
public func <£^> <A, B>(
    _ fn: @escaping (A) -> B,
    _ ne: NonEmpty<A?>
) -> NonEmpty<B?> {
    ne.mapT(fn)
}

// (<&^>) :: NonEmpty<A?> -> (A -> B) -> NonEmpty<B?>
public func <&^> <A, B>(
    _ ne: NonEmpty<A?>,
    _ fn: @escaping (A) -> B
) -> NonEmpty<B?> {
    ne.mapT(fn)
}
