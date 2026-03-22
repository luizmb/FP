import Foundation
import Core

public extension Writer {
    // WriterT + Either — Writer<W, Either<L, A>>

    /// flatMapT :: Writer<w, Either<l, a>> -> (a -> Writer<w, Either<l, b>>) -> Writer<w, Either<l, b>>
    /// .left(l)   → Writer(.left(l), log)
    /// .right(a)  → Writer(result, W.combine(log, innerLog))
    func flatMapT<L, Inner, B>(
        _ fn: @escaping (Inner) -> Writer<W, Either<L, B>>
    ) -> Writer<W, Either<L, B>> where A == Either<L, Inner> {
        switch value {
        case .left(let l): return Writer<W, Either<L, B>>(.left(l), log)
        case .right(let a):
            let wb = fn(a)
            return Writer<W, Either<L, B>>(wb.value, W.combine(log, wb.log))
        }
    }

    static func bindT<L, Inner, B>(
        _ fn: @escaping (Inner) -> Writer<W, Either<L, B>>
    ) -> (Writer<W, Either<L, Inner>>) -> Writer<W, Either<L, B>>
    where A == Either<L, Inner> {
        { $0.flatMapT(fn) }
    }
}
