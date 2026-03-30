import DataStructure
import CoreFPOperators

// MARK: - Monad operators for NonEmpty

// (>>-) :: NonEmpty<A> -> (A -> NonEmpty<B>) -> NonEmpty<B>
public func >>- <A, B>(
    _ ne: NonEmpty<A>,
    _ fn: @escaping (A) -> NonEmpty<B>
) -> NonEmpty<B> {
    ne.flatMap(fn)
}

// (-<<) :: (A -> NonEmpty<B>) -> NonEmpty<A> -> NonEmpty<B>
public func -<< <A, B>(
    _ fn: @escaping (A) -> NonEmpty<B>,
    _ ne: NonEmpty<A>
) -> NonEmpty<B> {
    ne.flatMap(fn)
}

// (>=>) :: (O -> NonEmpty<A>) -> (A -> NonEmpty<B>) -> O -> NonEmpty<B>
public func >=> <O, A, B>(
    _ fn1: @escaping (O) -> NonEmpty<A>,
    _ fn2: @escaping (A) -> NonEmpty<B>
) -> (O) -> NonEmpty<B> {
    NonEmpty.kleisli(fn1, fn2)
}

// (<=<) :: (A -> NonEmpty<B>) -> (O -> NonEmpty<A>) -> O -> NonEmpty<B>
public func <=< <O, A, B>(
    _ fn2: @escaping (A) -> NonEmpty<B>,
    _ fn1: @escaping (O) -> NonEmpty<A>
) -> (O) -> NonEmpty<B> {
    NonEmpty.kleisliBack(fn2, fn1)
}
