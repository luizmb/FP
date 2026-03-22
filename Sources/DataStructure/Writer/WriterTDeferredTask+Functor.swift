import CoreFP

// WriterTDeferredTask: outer = Writer, inner = DeferredTask
// Type: Writer<W, DeferredTask<A>>

public extension Writer {
    func mapT<Inner: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> Writer<W, DeferredTask<B>>
    where A == DeferredTask<Inner> {
        Writer<W, DeferredTask<B>>(value.fmap(fn), log)
    }

    static func fmapT<Inner: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> (Writer<W, DeferredTask<Inner>>) -> Writer<W, DeferredTask<B>> {
        { $0.mapT(fn) }
    }
}
