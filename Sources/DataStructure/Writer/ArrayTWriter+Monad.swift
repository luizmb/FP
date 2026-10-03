// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ArrayTWriter: outer = Array, inner = Writer
// Type: [Writer<W, A>]  (Haskell: WriterT w [] a)
//
// flatMapT is WriterT's bind: the continuation returns the full stack, so it can branch
// (several elements) or prune (empty) as well as log. Each result's log is prefixed by the
// log of the element it came from; order is outer element first, then continuation results.

public extension Array {
    /// flatMapT :: [Writer<w, a>] -> (a -> [Writer<w, b>]) -> [Writer<w, b>]
    /// for each w1, for each w2 in fn(w1.value): Writer(w2.value, w1.log <> w2.log)
    func flatMapT<W: Monoid, A, B>(_ fn: (A) -> [Writer<W, B>]) -> [Writer<W, B>]
    where Element == Writer<W, A> {
        flatMap { w1 in fn(w1.value).map { w2 in Writer(w2.value, W.combine(w1.log, w2.log)) } }
    }

    /// bindT :: (a -> [Writer<w, b>]) -> [Writer<w, a>] -> [Writer<w, b>]
    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> [Writer<W, B>]
    ) -> @Sendable ([Writer<W, A>]) -> [Writer<W, B>] {
        { arr in arr.flatMapT(fn) }
    }
}

/// Kleisli composition for `ArrayT + Writer` (left-to-right)
/// (>=>) :: (a -> [Writer<w, b>]) -> (b -> [Writer<w, c>]) -> a -> [Writer<w, c>]
public func kleisliT<W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> [Writer<W, B>],
    _ fn2: @escaping @Sendable (B) -> [Writer<W, C>]
) -> @Sendable (A) -> [Writer<W, C>] {
    { a in fn1(a).flatMapT(fn2) }
}
