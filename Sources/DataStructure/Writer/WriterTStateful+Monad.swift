import Foundation
import CoreFP

// WriterT + Stateful — Writer<W, Stateful<S, A>>
//
// flatMapT keeps the outer log; inner logs from fn are discarded.
// Stateful is lazy — fn produces different Writer logs per state,
// but the outer Writer accumulates logs eagerly. Use Writer<W, Either> or
// Writer<W, A?> when inner logs must be preserved.

public extension Writer {
    func flatMapT<S, Inner, B>(
        _ fn: @escaping (Inner) -> Writer<W, Stateful<S, B>>
    ) -> Writer<W, Stateful<S, B>> where A == Stateful<S, Inner> {
        Writer<W, Stateful<S, B>>(
            value.flatMap { inner in fn(inner).value },
            log
        )
    }

    static func bindT<S, Inner, B>(
        _ fn: @escaping (Inner) -> Writer<W, Stateful<S, B>>
    ) -> (Writer<W, Stateful<S, Inner>>) -> Writer<W, Stateful<S, B>>
    where A == Stateful<S, Inner> {
        { $0.flatMapT(fn) }
    }
}
