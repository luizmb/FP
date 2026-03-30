import CoreFPOperators
import DataStructure

// MARK: - ReaderT + Result

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env, A, B, E: Error>(
    _ reader: Reader<Env, Result<A, E>>,
    _ fn: @escaping (A) -> Reader<Env, Result<B, E>>
) -> Reader<Env, Result<B, E>> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env, A, B, E: Error>(
    _ fn: @escaping (A) -> Reader<Env, Result<B, E>>,
    _ reader: Reader<Env, Result<A, E>>
) -> Reader<Env, Result<B, E>> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env, A, B, C, E: Error>(
    _ fn1: @escaping (A) -> Reader<Env, Result<B, E>>,
    _ fn2: @escaping (B) -> Reader<Env, Result<C, E>>
) -> (A) -> Reader<Env, Result<C, E>> {
    { a in fn1(a).flatMapT(fn2) }
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <Env, A, B, E: Error>(
    _ reader: Reader<Env, Result<A, E>>,
    _ transform: @escaping (A) -> B
) -> Reader<Env, Result<B, E>> where A: Sendable {
    reader.mapT(transform)
}
