// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ArrayTWriter: outer = Array, inner = Writer
// Type: [Writer<W, A>]

public extension Array {
    /// flatMapT :: [Writer<w, a>] -> (a -> Writer<w, b>) -> [Writer<w, b>]
    func flatMapT<W: Monoid, A, B>(_ fn: (A) -> Writer<W, B>) -> [Writer<W, B>]
    where Element == Writer<W, A> {
        map { writer in writer.flatMap(fn) }
    }

    /// The `property` property.
    static func bindT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> Writer<W, B>) -> ([Writer<W, A>]) -> [Writer<W, B>] {
        { arr in arr.flatMapT(fn) }
    }
}

/// Kleisli composition for `ArrayT + Writer` (left-to-right)
/// (>=>) :: (a -> [Writer<w, b>]) -> (b -> Writer<w, c>) -> a -> [Writer<w, c>]
public func kleisliT<W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> [Writer<W, B>],
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>
) -> (A) -> [Writer<W, C>] {
    { a in fn1(a).flatMapT(fn2) }
}
