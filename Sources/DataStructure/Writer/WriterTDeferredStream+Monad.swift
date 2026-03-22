import CoreFP

// WriterTDeferredStream: outer = Writer, inner = DeferredStream
// Type: Writer<W, DeferredStream<A>>
//
// flatMapT keeps the outer log; inner fn logs are concatenated.

public extension Writer {
    func flatMapT<Inner: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, DeferredStream<B>>
    ) -> Writer<W, DeferredStream<B>>
    where A == DeferredStream<Inner> {
        let outerLog = log
        let innerStream = value.flatMap { a -> DeferredStream<B> in
            fn(a).value
        }
        return Writer<W, DeferredStream<B>>(innerStream, outerLog)
    }
}
