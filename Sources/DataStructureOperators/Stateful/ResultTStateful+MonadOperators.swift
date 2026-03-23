import DataStructure
import CoreFPOperators
import CoreFP

// (>>-) :: Result<Stateful<s, a>, e> -> (a -> Stateful<s, b>) -> Result<Stateful<s, b>, e>
public func >>- <S, A, B, E: Error>(_ result: Result<Stateful<S, A>, E>, _ fn: @escaping (A) -> Stateful<S, B>) -> Result<Stateful<S, B>, E> {
    result.flatMapT(fn)
}

// (-<<) :: (a -> Stateful<s, b>) -> Result<Stateful<s, a>, e> -> Result<Stateful<s, b>, e>
public func -<< <S, A, B, E: Error>(_ fn: @escaping (A) -> Stateful<S, B>, _ result: Result<Stateful<S, A>, E>) -> Result<Stateful<S, B>, E> {
    result.flatMapT(fn)
}

// (>=>) :: (a -> Result<Stateful<s, b>, e>) -> (b -> Stateful<s, c>) -> a -> Result<Stateful<s, c>, e>
public func >=> <S, A, B, C, E: Error>(
    _ fn1: @escaping (A) -> Result<Stateful<S, B>, E>,
    _ fn2: @escaping (B) -> Stateful<S, C>
) -> (A) -> Result<Stateful<S, C>, E> {
    { a in fn1(a).flatMapT(fn2) }
}
