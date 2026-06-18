// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Functor

/// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, A1>(_ transform: @escaping @Sendable (A) -> A1, _ array: [A]) -> [A1] {
    Array.fmap(transform)(array)
}

/// ($>) :: Functor f => f a -> b -> f b
public func £> <A, A1: Sendable>(_ array: [A], _ value: A1) -> [A1] {[A].fmap(const(value))(array)
}

/// (<$) :: a -> f b -> f a
public func <£ <A, A1: Sendable>(_ value: A1, _ array: [A]) -> [A1] {
    array £> value
}

/// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <A, A1>(_ array: [A], _ transform: @escaping @Sendable (A) -> A1) -> [A1] {
    Array.fmap(transform)(array)
}
