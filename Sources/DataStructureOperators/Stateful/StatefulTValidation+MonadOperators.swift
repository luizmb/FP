import DataStructure
import CoreFPOperators
import CoreFP

// (>>-) :: Stateful<s, Validation<e, a>> -> (a -> Stateful<s, Validation<e, b>>) -> Stateful<s, Validation<e, b>>
public func >>- <S, E: Semigroup, A, B>(
    _ stateful: Stateful<S, Validation<E, A>>,
    _ fn: @escaping (A) -> Stateful<S, Validation<E, B>>
) -> Stateful<S, Validation<E, B>> {
    flatMapTStatefulValidation(stateful, fn)
}

// (-<<) :: (a -> Stateful<s, Validation<e, b>>) -> Stateful<s, Validation<e, a>> -> Stateful<s, Validation<e, b>>
public func -<< <S, E: Semigroup, A, B>(
    _ fn: @escaping (A) -> Stateful<S, Validation<E, B>>,
    _ stateful: Stateful<S, Validation<E, A>>
) -> Stateful<S, Validation<E, B>> {
    flatMapTStatefulValidation(stateful, fn)
}

// (>=>) :: (a -> Stateful<s, Validation<e,b>>) -> (b -> Stateful<s, Validation<e,c>>) -> a -> Stateful<s, Validation<e,c>>
public func >=> <S, E: Semigroup, A, B, C>(
    _ fn1: @escaping (A) -> Stateful<S, Validation<E, B>>,
    _ fn2: @escaping (B) -> Stateful<S, Validation<E, C>>
) -> (A) -> Stateful<S, Validation<E, C>> {
    { a in flatMapTStatefulValidation(fn1(a), fn2) }
}
