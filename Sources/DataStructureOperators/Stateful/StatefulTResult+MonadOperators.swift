import DataStructure
import CoreFPOperators
import CoreFP

// (>>-) :: Stateful<s, Result<a, e>> -> (a -> Stateful<s, Result<b, e>>) -> Stateful<s, Result<b, e>>
public func >>- <S, A, B, E: Error>(_ stateful: Stateful<S, Result<A, E>>, _ fn: @escaping (A) -> Stateful<S, Result<B, E>>) -> Stateful<S, Result<B, E>> {
    stateful.flatMapT(fn)
}

// (-<<) :: (a -> Stateful<s, Result<b, e>>) -> Stateful<s, Result<a, e>> -> Stateful<s, Result<b, e>>
public func -<< <S, A, B, E: Error>(_ fn: @escaping (A) -> Stateful<S, Result<B, E>>, _ stateful: Stateful<S, Result<A, E>>) -> Stateful<S, Result<B, E>> {
    stateful.flatMapT(fn)
}

// (>=>) :: (a -> Stateful<s, Result<b, e>>) -> (b -> Stateful<s, Result<c, e>>) -> a -> Stateful<s, Result<c, e>>
public func >=> <S, A, B, C, E: Error>(
    _ fn1: @escaping (A) -> Stateful<S, Result<B, E>>,
    _ fn2: @escaping (B) -> Stateful<S, Result<C, E>>
) -> (A) -> Stateful<S, Result<C, E>> {
    { a in fn1(a).flatMapT(fn2) }
}
