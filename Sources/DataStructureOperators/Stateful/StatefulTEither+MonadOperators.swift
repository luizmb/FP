import CoreFPOperators
import DataStructure

// (>>-) :: Stateful<s, Either<l, a>> -> (a -> Stateful<s, Either<l, b>>) -> Stateful<s, Either<l, b>>
public func >>- <S, L, A, B>(
    _ stateful: Stateful<S, Either<L, A>>,
    _ fn: @escaping (A) -> Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, B>> {
    stateful.flatMapT(fn)
}

// (-<<) :: (a -> Stateful<s, Either<l, b>>) -> Stateful<s, Either<l, a>> -> Stateful<s, Either<l, b>>
public func -<< <S, L, A, B>(
    _ fn: @escaping (A) -> Stateful<S, Either<L, B>>,
    _ stateful: Stateful<S, Either<L, A>>
) -> Stateful<S, Either<L, B>> {
    stateful.flatMapT(fn)
}

// (>=>) :: (a -> Stateful<s, Either<l, b>>) -> (b -> Stateful<s, Either<l, c>>) -> a -> Stateful<s, Either<l, c>>
public func >=> <S, L, A, B, C>(
    _ fn1: @escaping (A) -> Stateful<S, Either<L, B>>,
    _ fn2: @escaping (B) -> Stateful<S, Either<L, C>>
) -> (A) -> Stateful<S, Either<L, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
