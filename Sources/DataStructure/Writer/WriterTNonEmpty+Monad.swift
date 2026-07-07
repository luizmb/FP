// SPDX-License-Identifier: Apache-2.0
import CoreFP

// WriterTNonEmpty: outer = Writer, inner = NonEmpty
// Type: Writer<W, NonEmpty<A>>

public extension Writer {
    /// flatMapT for Writer<W, NonEmpty<A>>.
    /// Each element maps to a Writer<W, NonEmpty<B>?>; logs are combined, NonEmpties concatenated.
    func flatMapT<Inner, B>(
        _ fn: (Inner) -> Writer<W, NonEmpty<B>?>
    ) -> Writer<W, NonEmpty<B>?> where A == NonEmpty<Inner> {
        let results = value.toArray.map(fn)
        let nonEmpties = results.compactMap(\.value)
        let combinedLog = results.reduce(log) { acc, wb in W.combine(acc, wb.log) }
        let combined: NonEmpty<B>? = nonEmpties.first.map { first in
            nonEmpties.dropFirst().reduce(first, NonEmpty.combine)
        }
        return Writer<W, NonEmpty<B>?>(combined, combinedLog)
    }

    /// The `property` property.
    static func bindT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, NonEmpty<B>?>
    ) -> (Writer<W, NonEmpty<Inner>>) -> Writer<W, NonEmpty<B>?>
    where A == NonEmpty<Inner> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `WriterT + NonEmpty` (left-to-right)
/// (>=>) :: (a -> Writer<w, NonEmpty<b>?>) -> (b -> Writer<w, NonEmpty<c>?>) -> a -> Writer<w, NonEmpty<c>?>
///
/// Both arrows already return the fold-and-combine `NonEmpty<_>?` shape produced by `flatMapT`,
/// so composition re-applies the same "run + collect + NonEmpty.combine fold" idiom starting
/// from the (already optional) result of `fn1`, short-circuiting (but still combining logs) to
/// `nil` if it is empty.
public func kleisliT<W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, NonEmpty<B>?>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, NonEmpty<C>?>
) -> (A) -> Writer<W, NonEmpty<C>?> {
    { a in
        let wb = fn1(a)
        guard let nonEmptyB = wb.value else { return Writer<W, NonEmpty<C>?>(nil, wb.log) }
        let results = nonEmptyB.toArray.map(fn2)
        let nonEmpties = results.compactMap(\.value)
        let combinedLog = results.reduce(wb.log) { acc, wc in W.combine(acc, wc.log) }
        let combined: NonEmpty<C>? = nonEmpties.first.map { first in
            nonEmpties.dropFirst().reduce(first, NonEmpty.combine)
        }
        return Writer<W, NonEmpty<C>?>(combined, combinedLog)
    }
}
