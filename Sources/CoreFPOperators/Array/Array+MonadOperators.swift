// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Monad

/// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <A, A1>(_ array: [A], _ fn: @escaping @Sendable (A) -> [A1]) -> [A1] {
    array.flatMap(fn)
}

/// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <A, A1>(_ fn: @escaping @Sendable (A) -> [A1], _ array: [A]) -> [A1] {
    array.flatMap(fn)
}

/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A0, A, A1>(
    _ fn1: @escaping @Sendable (A0) -> [A],
    _ fn2: @escaping @Sendable (A) -> [A1]
) -> (A0) -> [A1] {
    Array.kleisli(fn1, fn2)
}
