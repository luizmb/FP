import Foundation
import CoreFP

// WriterT + DeferredStream — free functions for Writer<W, DeferredStream<A>>

/// apply for Writer<W, DeferredStream>
public func applyWriterDeferredStream<W: Monoid, A: Sendable, B: Sendable>(
    _ wf: Writer<W, DeferredStream<@Sendable (A) -> B>>,
    _ wa: Writer<W, DeferredStream<A>>
) -> Writer<W, DeferredStream<B>> {
    Writer<W, DeferredStream<B>>(
        applyDeferredStream(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, DeferredStream>
public func liftA2WriterDeferredStream<W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, DeferredStream<A>>, Writer<W, DeferredStream<B>>) -> Writer<W, DeferredStream<C>> {
    { wa, wb in
        Writer<W, DeferredStream<C>>(
            liftA2DeferredStream(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, DeferredStream>
public func seqRightWriterDeferredStream<W: Monoid, A: Sendable, B: Sendable>(
    _ lhs: Writer<W, DeferredStream<A>>,
    _ rhs: Writer<W, DeferredStream<B>>
) -> Writer<W, DeferredStream<B>> {
    Writer<W, DeferredStream<B>>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, DeferredStream>
public func seqLeftWriterDeferredStream<W: Monoid, A: Sendable, B: Sendable>(
    _ lhs: Writer<W, DeferredStream<A>>,
    _ rhs: Writer<W, DeferredStream<B>>
) -> Writer<W, DeferredStream<A>> {
    Writer<W, DeferredStream<A>>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
