// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// WriterT + Stateful — Writer<W, Stateful<S, A>>
//
// flatMapT keeps the outer log; inner logs from fn are discarded.
// Stateful is lazy — fn produces different Writer logs per state,
// but the outer Writer accumulates logs eagerly. Use Writer<W, Either> or
// Writer<W, A?> when inner logs must be preserved.

public extension Writer {
    /// Declaration.
    func flatMapT<S, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Stateful<S, B>>
    ) -> Writer<W, Stateful<S, B>> where A == Stateful<S, Inner> {
        Writer<W, Stateful<S, B>>(
            value.flatMap { inner in fn(inner).value },
            log
        )
    }

    /// The `property` property.
    static func bindT<S, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Stateful<S, B>>
    ) -> (Writer<W, Stateful<S, Inner>>) -> Writer<W, Stateful<S, B>>
    where A == Stateful<S, Inner> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `WriterT + Stateful` (left-to-right)
/// (>=>) :: (a -> Writer<w, Stateful<s, b>>) -> (b -> Writer<w, Stateful<s, c>>) -> a -> Writer<w, Stateful<s, c>>
public func kleisliT<W: Monoid, S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, Stateful<S, B>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, Stateful<S, C>>
) -> (A) -> Writer<W, Stateful<S, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
