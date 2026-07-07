// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <A: Semigroup, B, C>(_ these: These<A, B>, _ fn: @escaping @Sendable (B) -> These<A, C>) -> These<A, C> {
    these.flatMap(fn)
}

/// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <A: Semigroup, B, C>(_ fn: @escaping @Sendable (B) -> These<A, C>, _ these: These<A, B>) -> These<A, C> {
    these.flatMap(fn)
}

/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A: Semigroup, B0, B, C>(
    _ fn1: @escaping @Sendable (B0) -> These<A, B>,
    _ fn2: @escaping @Sendable (B) -> These<A, C>
) -> (B0) -> These<A, C> {
    These.kleisli(fn1, fn2)
}

/// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <A, B, C>(_ these: These<A, B>, _ transform: @escaping @Sendable (B) -> C) -> These<A, C> {
    these.map(transform)
}
