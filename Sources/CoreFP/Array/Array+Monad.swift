// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Array {
    /// Curried version of Swift's native flatMap for functional composition
    /// (>>=) :: m a -> (a -> m b) -> m b
    static func bind<A1>(
        _ fn: @escaping @Sendable (Element) -> [A1]
    ) -> ([Element]) -> [A1] {
        { array in
            array.flatMap(fn)
        }
    }

    /// Kleisli composition (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<A0, A1>(
        _ fn1: @escaping @Sendable (A0) -> [Element],
        _ fn2: @escaping @Sendable (Element) -> [A1]
    ) -> (A0) -> [A1] {
        { a0 in
            fn1(a0).flatMap(fn2)
        }
    }

    /// Kleisli composition (right-to-left)
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<A0, A1>(
        _ fn2: @escaping @Sendable (Element) -> [A1],
        _ fn1: @escaping @Sendable (A0) -> [Element]
    ) -> (A0) -> [A1] {
        { a0 in
            fn1(a0).flatMap(fn2)
        }
    }

    /// Alternative operation - concatenates two arrays
    /// (<|>) :: [a] -> [a] -> [a]
    static func alt(_ lhs: [Element], _ rhs: @autoclosure () -> [Element]) -> [Element] {
        lhs + rhs()
    }

    /// Concatenates an array of arrays
    /// concat :: [[a]] -> [a]
    static func concat(_ arrays: [[Element]]) -> [Element] {
        arrays.flatMap(CoreFP.id)
    }

    /// Monadic join - flattens nested arrays
    /// join :: m (m a) -> m a
    static func join(_ nested: [[Element]]) -> [Element] {
        nested.flatMap(CoreFP.id)
    }

    /// Discards the values, keeping only the structure
    /// void :: m a -> m ()
    func void() -> [Void] {
        map(ignore)
    }

    /// Monadic filter (curried version)
    /// filter :: (a -> Bool) -> [a] -> [a]
    static func filterM(_ predicate: @escaping @Sendable (Element) -> Bool) -> ([Element]) -> [Element] {
        { array in
            array.filter(predicate)
        }
    }
}
