import CoreFPOperators
import DataStructure

// (>>-) :: Stateful<s, a> -> (a -> Stateful<s, b>) -> Stateful<s, b>
public func >>- <S, A, B>(
    _ stateful: Stateful<S, A>,
    _ fn: @escaping @Sendable (A) -> Stateful<S, B>
) -> Stateful<S, B> {
    stateful.flatMap(fn)
}

// (-<<) :: (a -> Stateful<s, b>) -> Stateful<s, a> -> Stateful<s, b>
public func -<< <S, A, B>(
    _ fn: @escaping @Sendable (A) -> Stateful<S, B>,
    _ stateful: Stateful<S, A>
) -> Stateful<S, B> {
    stateful.flatMap(fn)
}

// (>=>) :: (a -> Stateful<s, b>) -> (b -> Stateful<s, c>) -> a -> Stateful<s, c>
public func >=> <S, O0, A, B>(
    _ fn1: @escaping @Sendable (O0) -> Stateful<S, A>,
    _ fn2: @escaping @Sendable (A) -> Stateful<S, B>
) -> (O0) -> Stateful<S, B> {
    Stateful.kleisli(fn1, fn2)
}
