// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// OptionalTWriter: outer = Optional, inner = Writer
// Type: Writer<W, A>? = Optional<Writer<W, A>>  (Haskell: WriterT w Maybe a)
//
// flatMapT is WriterT's bind: the continuation returns the full stack, so it can fail
// (`nil`) as well as log. `nil` short-circuits; logs combine left to right.

public extension Optional {
    /// flatMapT :: Writer<w, a>? -> (a -> Writer<w, b>?) -> Writer<w, b>?
    /// nil      → nil
    /// some(w1) → fn(w1.value): nil → nil; some(w2) → some(Writer(w2.value, w1.log <> w2.log))
    func flatMapT<W: Monoid, A, B>(_ fn: (A) -> Writer<W, B>?) -> Writer<W, B>?
    where Wrapped == Writer<W, A> {
        flatMap { w1 in fn(w1.value).map { w2 in Writer(w2.value, W.combine(w1.log, w2.log)) } }
    }

    /// bindT :: (a -> Writer<w, b>?) -> Writer<w, a>? -> Writer<w, b>?
    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> Writer<W, B>?
    ) -> @Sendable (Writer<W, A>?) -> Writer<W, B>? {
        { opt in opt.flatMapT(fn) }
    }
}

/// Kleisli composition for `OptionalT + Writer` (left-to-right)
/// (>=>) :: (a -> Writer<w, b>?) -> (b -> Writer<w, c>?) -> a -> Writer<w, c>?
public func kleisliT<W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, B>?,
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>?
) -> @Sendable (A) -> Writer<W, C>? {
    { a in fn1(a).flatMapT(fn2) }
}
