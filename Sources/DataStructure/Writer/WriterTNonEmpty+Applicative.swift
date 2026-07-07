// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// WriterT + NonEmpty — free functions for Writer<W, NonEmpty<A>>

/// apply for Writer<W, NonEmpty>
public func applyWriterNonEmpty<W: Monoid, A, B>(
    _ wf: Writer<W, NonEmpty<@Sendable (A) -> B>>,
    _ wa: Writer<W, NonEmpty<A>>
) -> Writer<W, NonEmpty<B>> {
    Writer<W, NonEmpty<B>>(
        NonEmpty.apply(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, NonEmpty>
public func liftA2WriterNonEmpty<W: Monoid, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, NonEmpty<A>>, Writer<W, NonEmpty<B>>) -> Writer<W, NonEmpty<C>> where A: Sendable {
    { wa, wb in
        Writer<W, NonEmpty<C>>(
            NonEmpty.liftA2(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, NonEmpty>
public func seqRightWriterNonEmpty<W: Monoid, A, B>(
    _ lhs: Writer<W, NonEmpty<A>>,
    _ rhs: Writer<W, NonEmpty<B>>
) -> Writer<W, NonEmpty<B>> {
    Writer<W, NonEmpty<B>>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, NonEmpty>
public func seqLeftWriterNonEmpty<W: Monoid, A, B>(
    _ lhs: Writer<W, NonEmpty<A>>,
    _ rhs: Writer<W, NonEmpty<B>>
) -> Writer<W, NonEmpty<A>> {
    Writer<W, NonEmpty<A>>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
