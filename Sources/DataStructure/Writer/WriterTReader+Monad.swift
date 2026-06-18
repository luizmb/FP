// SPDX-License-Identifier: Apache-2.0
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
