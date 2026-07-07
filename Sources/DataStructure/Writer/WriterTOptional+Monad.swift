// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Writer {
    // WriterT + Optional — Writer<W, A?>

    /// flatMapT :: Writer<w, a?> -> (a -> Writer<w, b?>) -> Writer<w, b?>
    /// nil      → Writer(nil, log)
    /// some(a)  → Writer(b?, W.combine(log, innerLog))
    func flatMapT<Inner, B>(_ fn: (Inner) -> Writer<W, B?>) -> Writer<W, B?> where A == Inner? {
        guard let a = value else { return Writer<W, B?>(nil, log) }
        let wb = fn(a)
        return Writer<W, B?>(wb.value, W.combine(log, wb.log))
    }

    /// The `property` property.
    static func bindT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, B?>
    ) -> (Writer<W, Inner?>) -> Writer<W, B?> where A == Inner? {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `WriterT + Optional` (left-to-right)
/// (>=>) :: (a -> Writer<w, b?>) -> (b -> Writer<w, c?>) -> a -> Writer<w, c?>
public func kleisliT<W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, B?>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, C?>
) -> (A) -> Writer<W, C?> {
    { a in fn1(a).flatMapT(fn2) }
}
