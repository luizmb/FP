// SPDX-License-Identifier: Apache-2.0
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
        case let .failure(e):
            return Writer<W, Result<B, E>>(.failure(e), log)

        case let .success(a):
            let wb = fn(a)
            return Writer<W, Result<B, E>>(wb.value, W.combine(log, wb.log))
        }
    }

    /// The `property` property.
    static func bindT<Inner, B, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Result<B, E>>
    ) -> (Writer<W, Result<Inner, E>>) -> Writer<W, Result<B, E>>
    where A == Result<Inner, E> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `WriterT + Result` (left-to-right)
/// (>=>) :: (a -> Writer<w, Result<b, e>>) -> (b -> Writer<w, Result<c, e>>) -> a -> Writer<w, Result<c, e>>
public func kleisliT<W: Monoid, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, Result<C, E>>
) -> (A) -> Writer<W, Result<C, E>> {
    { a in fn1(a).flatMapT(fn2) }
}
