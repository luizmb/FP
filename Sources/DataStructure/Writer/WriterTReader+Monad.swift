// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// WriterT + Reader — Writer<W, Reader<Env, A>>
//
// flatMapT keeps the outer log; inner logs from fn are discarded.
// Reader is lazy — fn produces different Writer logs per environment,
// but the outer Writer accumulates logs eagerly. Use Writer<W, Either> or
// Writer<W, A?> when inner logs must be preserved.

public extension Writer {
    /// Declaration.
    func flatMapT<Env, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Reader<Env, B>>
    ) -> Writer<W, Reader<Env, B>> where A == Reader<Env, Inner> {
        Writer<W, Reader<Env, B>>(
            value.flatMap { inner in fn(inner).value },
            log
        )
    }

    /// The `property` property.
    static func bindT<Env, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Reader<Env, B>>
    ) -> (Writer<W, Reader<Env, Inner>>) -> Writer<W, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `WriterT + Reader` (left-to-right)
/// (>=>) :: (a -> Writer<w, Reader<env, b>>) -> (b -> Writer<w, Reader<env, c>>) -> a -> Writer<w, Reader<env, c>>
public func kleisliT<W: Monoid, Env, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, Reader<Env, B>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, Reader<Env, C>>
) -> (A) -> Writer<W, Reader<Env, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
