import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Writer<w, DeferredStream<(a -> b)>> -> Writer<w, DeferredStream<a>> -> Writer<w, DeferredStream<b>>
public func <*> <W: Monoid, A: Sendable, B: Sendable>(_ wf: Writer<W, DeferredStream<@Sendable (A) -> B>>, _ wa: Writer<W, DeferredStream<A>>) -> Writer<W, DeferredStream<B>> {
    applyWriterDeferredStream(wf, wa)
}

// (*>) :: Writer<w, DeferredStream<a>> -> Writer<w, DeferredStream<b>> -> Writer<w, DeferredStream<b>>
public func *> <W: Monoid, A: Sendable, B: Sendable>(_ lhs: Writer<W, DeferredStream<A>>, _ rhs: Writer<W, DeferredStream<B>>) -> Writer<W, DeferredStream<B>> {
    seqRightWriterDeferredStream(lhs, rhs)
}

// (<*) :: Writer<w, DeferredStream<a>> -> Writer<w, DeferredStream<b>> -> Writer<w, DeferredStream<a>>
public func <* <W: Monoid, A: Sendable, B: Sendable>(_ lhs: Writer<W, DeferredStream<A>>, _ rhs: Writer<W, DeferredStream<B>>) -> Writer<W, DeferredStream<A>> {
    seqLeftWriterDeferredStream(lhs, rhs)
}
