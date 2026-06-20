// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// MARK: - ReaderT + Optional

/// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env, A, B>(
    _ reader: Reader<Env, A?>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, B?>
) -> Reader<Env, B?> {
    reader.flatMapT(fn)
}

/// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env, A, B>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, B?>,
    _ reader: Reader<Env, A?>
) -> Reader<Env, B?> {
    reader.flatMapT(fn)
}

/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, B?>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, C?>
) -> (A) -> Reader<Env, C?> {
    { a in fn1(a).flatMapT(fn2) }
}

/// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <Env, A, B>(
    _ reader: Reader<Env, A?>,
    _ transform: @escaping @Sendable (A) -> B
) -> Reader<Env, B?> where A: Sendable {
    reader.mapT(transform)
}
