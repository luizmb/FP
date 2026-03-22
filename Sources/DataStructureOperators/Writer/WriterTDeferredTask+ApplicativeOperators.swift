import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Writer<w, DeferredTask<(a -> b)>> -> Writer<w, DeferredTask<a>> -> Writer<w, DeferredTask<b>>
public func <*> <W: Monoid, A: Sendable, B: Sendable>(_ wf: Writer<W, DeferredTask<@Sendable (A) -> B>>, _ wa: Writer<W, DeferredTask<A>>) -> Writer<W, DeferredTask<B>> {
    applyWriterDeferredTask(wf, wa)
}

// (*>) :: Writer<w, DeferredTask<a>> -> Writer<w, DeferredTask<b>> -> Writer<w, DeferredTask<b>>
public func *> <W: Monoid, A: Sendable, B: Sendable>(_ lhs: Writer<W, DeferredTask<A>>, _ rhs: Writer<W, DeferredTask<B>>) -> Writer<W, DeferredTask<B>> {
    seqRightWriterDeferredTask(lhs, rhs)
}

// (<*) :: Writer<w, DeferredTask<a>> -> Writer<w, DeferredTask<b>> -> Writer<w, DeferredTask<a>>
public func <* <W: Monoid, A: Sendable, B: Sendable>(_ lhs: Writer<W, DeferredTask<A>>, _ rhs: Writer<W, DeferredTask<B>>) -> Writer<W, DeferredTask<A>> {
    seqLeftWriterDeferredTask(lhs, rhs)
}
