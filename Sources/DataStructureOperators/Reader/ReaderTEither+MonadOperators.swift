// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// MARK: - ReaderT + Either

/// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env: Sendable, L: Sendable, A: Sendable, B: Sendable>(
    _ reader: Reader<Env, Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, B>> {
    reader.flatMapT(fn)
}

/// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env: Sendable, L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, Either<L, B>>,
    _ reader: Reader<Env, Either<L, A>>
) -> Reader<Env, Either<L, B>> {
    reader.flatMapT(fn)
}

/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env: Sendable, L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Either<L, B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Either<L, C>>
) -> (A) -> Reader<Env, Either<L, C>> {
    kleisliT(fn1, fn2)
}
