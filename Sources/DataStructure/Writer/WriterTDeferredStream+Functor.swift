import CoreFP

// WriterTDeferredStream: outer = Writer, inner = DeferredStream
// Type: Writer<W, DeferredStream<A>>

public extension Writer {
    func mapT<Inner: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> Writer<W, DeferredStream<B>>
    where A == DeferredStream<Inner> {
        Writer<W, DeferredStream<B>>(value.map(fn), log)
    }

    static func fmapT<Inner: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> (Writer<W, DeferredStream<Inner>>) -> Writer<W, DeferredStream<B>> {
        { $0.mapT(fn) }
    }
}

// Free function alternative
public func mapTWriterDeferredStream<W: Monoid, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, DeferredStream<A>>
) -> Writer<W, DeferredStream<B>> {
    Writer<W, DeferredStream<B>>(writer.value.map(fn), writer.log)
}

public func fmapTWriterDeferredStream<W: Monoid, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Writer<W, DeferredStream<A>>) -> Writer<W, DeferredStream<B>> {
    { writer in mapTWriterDeferredStream(fn, writer) }
}
