import FP
import Reader
import Operators

// MARK: - ReaderT + Optional

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env, A, B>(
    _ reader: Reader<Env, A?>,
    _ fn: @escaping (A) -> Reader<Env, B?>
) -> Reader<Env, B?> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env, A, B>(
    _ fn: @escaping (A) -> Reader<Env, B?>,
    _ reader: Reader<Env, A?>
) -> Reader<Env, B?> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env, A, B, C>(
    _ fn1: @escaping (A) -> Reader<Env, B?>,
    _ fn2: @escaping (B) -> Reader<Env, C?>
) -> (A) -> Reader<Env, C?> {
    { a in fn1(a).flatMapT(fn2) }
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <Env, A, B>(
    _ reader: Reader<Env, A?>,
    _ transform: @escaping (A) -> B
) -> Reader<Env, B?> where A: Sendable {
    reader.mapT(transform)
}

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

// MARK: - ReaderT + Array

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env, A, B>(
    _ reader: Reader<Env, [A]>,
    _ fn: @escaping (A) -> Reader<Env, [B]>
) -> Reader<Env, [B]> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env, A, B>(
    _ fn: @escaping (A) -> Reader<Env, [B]>,
    _ reader: Reader<Env, [A]>
) -> Reader<Env, [B]> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env, A, B, C>(
    _ fn1: @escaping (A) -> Reader<Env, [B]>,
    _ fn2: @escaping (B) -> Reader<Env, [C]>
) -> (A) -> Reader<Env, [C]> {
    { a in fn1(a).flatMapT(fn2) }
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <Env, A, B>(
    _ reader: Reader<Env, [A]>,
    _ transform: @escaping (A) -> B
) -> Reader<Env, [B]> {
    reader.mapT(transform)
}
