import DataStructure
import Core
import CoreOperators

// MARK: - ReaderT + Reader (nested)

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env1, Env2, A, B>(
    _ reader: Reader<Env1, Reader<Env2, A>>,
    _ fn: @escaping (A) -> Reader<Env1, Reader<Env2, B>>
) -> Reader<Env1, Reader<Env2, B>> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env1, Env2, A, B>(
    _ fn: @escaping (A) -> Reader<Env1, Reader<Env2, B>>,
    _ reader: Reader<Env1, Reader<Env2, A>>
) -> Reader<Env1, Reader<Env2, B>> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env1, Env2, A, B, C>(
    _ fn1: @escaping (A) -> Reader<Env1, Reader<Env2, B>>,
    _ fn2: @escaping (B) -> Reader<Env1, Reader<Env2, C>>
) -> (A) -> Reader<Env1, Reader<Env2, C>> {
    { a in fn1(a).flatMapT(fn2) }
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <Env1, Env2, A, B>(
    _ reader: Reader<Env1, Reader<Env2, A>>,
    _ transform: @escaping (A) -> B
) -> Reader<Env1, Reader<Env2, B>> {
    reader.mapT(transform)
}
