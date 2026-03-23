import Foundation
import CoreFP

// WriterT + DeferredTask — free functions for Writer<W, DeferredTask<A>>

/// apply for Writer<W, DeferredTask>
public func applyWriterDeferredTask<W: Monoid, A: Sendable, B: Sendable>(
    _ wf: Writer<W, DeferredTask<@Sendable (A) -> B>>,
    _ wa: Writer<W, DeferredTask<A>>
) -> Writer<W, DeferredTask<B>> {
    Writer<W, DeferredTask<B>>(
        applyDeferredTask(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, DeferredTask>
public func liftA2WriterDeferredTask<W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, DeferredTask<A>>, Writer<W, DeferredTask<B>>) -> Writer<W, DeferredTask<C>> {
    { wa, wb in
        Writer<W, DeferredTask<C>>(
            liftA2DeferredTask(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, DeferredTask>
public func seqRightWriterDeferredTask<W: Monoid, A: Sendable, B: Sendable>(
    _ lhs: Writer<W, DeferredTask<A>>,
    _ rhs: Writer<W, DeferredTask<B>>
) -> Writer<W, DeferredTask<B>> {
    Writer<W, DeferredTask<B>>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, DeferredTask>
public func seqLeftWriterDeferredTask<W: Monoid, A: Sendable, B: Sendable>(
    _ lhs: Writer<W, DeferredTask<A>>,
    _ rhs: Writer<W, DeferredTask<B>>
) -> Writer<W, DeferredTask<A>> {
    Writer<W, DeferredTask<A>>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
