import CoreFP
import Foundation

public extension Writer {
    // WriterT + Result — Writer<W, Result<A, E>>

    /// flatMapT :: Writer<w, Result<a, e>> -> (a -> Writer<w, Result<b, e>>) -> Writer<w, Result<b, e>>
    /// .failure(e)  → Writer(.failure(e), log)
    /// .success(a)  → Writer(result, W.combine(log, innerLog))
    func flatMapT<Inner, B, E: Error>(
        _ fn: (Inner) -> Writer<W, Result<B, E>>
    ) -> Writer<W, Result<B, E>> where A == Result<Inner, E> {
        switch value {
        case .failure(let e): return Writer<W, Result<B, E>>(.failure(e), log)
        case .success(let a):
            let wb = fn(a)
            return Writer<W, Result<B, E>>(wb.value, W.combine(log, wb.log))
        }
    }

    static func bindT<Inner, B, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Result<B, E>>
    ) -> (Writer<W, Result<Inner, E>>) -> Writer<W, Result<B, E>>
    where A == Result<Inner, E> {
        { $0.flatMapT(fn) }
    }
}
