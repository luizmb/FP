// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Writer {
    // WriterT + Either — Writer<W, Either<L, A>>

    /// flatMapT :: Writer<w, Either<l, a>> -> (a -> Writer<w, Either<l, b>>) -> Writer<w, Either<l, b>>
    /// .left(l)   → Writer(.left(l), log)
    /// .right(a)  → Writer(result, W.combine(log, innerLog))
    func flatMapT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Either<L, B>>
    ) -> Writer<W, Either<L, B>> where A == Either<L, Inner> {
        switch value {
        case let .left(l):
            return Writer<W, Either<L, B>>(.left(l), log)

        case let .right(a):
            let wb = fn(a)
            return Writer<W, Either<L, B>>(wb.value, W.combine(log, wb.log))
        }
    }

    /// The `property` property.
    static func bindT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Either<L, B>>
    ) -> (Writer<W, Either<L, Inner>>) -> Writer<W, Either<L, B>>
    where A == Either<L, Inner> {
        { $0.flatMapT(fn) }
    }
}
