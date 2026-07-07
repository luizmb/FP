// SPDX-License-Identifier: Apache-2.0
import Foundation

// ArrayTStateful: outer = Array, inner = Stateful
// Type: [Stateful<S, A>] = Array<Stateful<S, A>>
//
// flatMapT sequences computations structurally: each Stateful<S, A> in the array
// is composed with fn via flatMap. Empty array propagates as empty array.

public extension Array {
    /// flatMapT :: [Stateful<s, a>] -> (a -> Stateful<s, b>) -> [Stateful<s, b>]
    func flatMapT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> [Stateful<S, B>]
    where Element == Stateful<S, A> {
        map { stateful in stateful.flatMap(fn) }
    }

    /// The `property` property.
    static func bindT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> ([Stateful<S, A>]) -> [Stateful<S, B>] {
        { arr in arr.flatMapT(fn) }
    }
}

/// Kleisli composition for `ArrayT + Stateful` (left-to-right)
/// (>=>) :: (a -> [Stateful<s, b>]) -> (b -> Stateful<s, c>) -> a -> [Stateful<s, c>]
public func kleisliT<S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> [Stateful<S, B>],
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>
) -> (A) -> [Stateful<S, C>] {
    { a in fn1(a).flatMapT(fn2) }
}
