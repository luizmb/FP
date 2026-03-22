import CoreFP

// WriterTDeferredTask: outer = Writer, inner = DeferredTask
// Type: Writer<W, DeferredTask<A>>
//
// flatMapT keeps the outer log; inner fn logs are appended.

public extension Writer {
    func flatMapT<Inner: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, DeferredTask<B>>
    ) -> Writer<W, DeferredTask<B>>
    where A == DeferredTask<Inner> {
        let outerLog = log
        let innerTask = value.flatMap { a -> DeferredTask<B> in fn(a).value }
        return Writer<W, DeferredTask<B>>(innerTask, outerLog)
    }
}
