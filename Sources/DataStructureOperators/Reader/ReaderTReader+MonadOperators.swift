// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// MARK: - ReaderT + Reader (nested)

/// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env1: Sendable, Env2: Sendable, A: Sendable, B: Sendable>(
    _ reader: Reader<Env1, Reader<Env2, A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env1, Reader<Env2, B>>
) -> Reader<Env1, Reader<Env2, B>> {
    reader.flatMapT(fn)
}

/// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env1: Sendable, Env2: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> Reader<Env1, Reader<Env2, B>>,
    _ reader: Reader<Env1, Reader<Env2, A>>
) -> Reader<Env1, Reader<Env2, B>> {
    reader.flatMapT(fn)
}

/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env1: Sendable, Env2: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env1, Reader<Env2, B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env1, Reader<Env2, C>>
) -> (A) -> Reader<Env1, Reader<Env2, C>> {
    kleisliT(fn1, fn2)
}
