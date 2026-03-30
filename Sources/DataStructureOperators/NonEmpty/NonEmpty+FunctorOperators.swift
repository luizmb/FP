import CoreFP
import CoreFPOperators
import DataStructure

// MARK: - Functor operators for NonEmpty

// (<£>) :: (A -> B) -> NonEmpty<A> -> NonEmpty<B>
public func <£> <A, B>(
    _ fn: @escaping (A) -> B,
    _ ne: NonEmpty<A>
) -> NonEmpty<B> {
    ne.fmap(fn)
}

// ($>) :: NonEmpty<A> -> B -> NonEmpty<B>
public func £> <A, B>(
    _ ne: NonEmpty<A>,
    _ value: B
) -> NonEmpty<B> {
    ne.fmap(const(value))
}

// (<$) :: B -> NonEmpty<A> -> NonEmpty<B>
public func <£ <A, B>(
    _ value: B,
    _ ne: NonEmpty<A>
) -> NonEmpty<B> {
    ne £> value
}

// (<&>) :: NonEmpty<A> -> (A -> B) -> NonEmpty<B>
public func <&> <A, B>(
    _ ne: NonEmpty<A>,
    _ fn: @escaping (A) -> B
) -> NonEmpty<B> {
    ne.fmap(fn)
}
