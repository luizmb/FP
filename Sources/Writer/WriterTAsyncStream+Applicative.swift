import Foundation
import FP

// WriterT + AsyncStream — free functions for Writer<W, AsyncStream<A>>

/// liftA2 for Writer<W, AsyncStream>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2WriterAsyncStream<W: Monoid, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, AsyncStream<A>>, Writer<W, AsyncStream<B>>) -> Writer<W, AsyncMapSequence<AsyncStream<(A, B)>, C>>
where A: Sendable, B: Sendable, C: Sendable {
    { wa, wb in
        Writer<W, AsyncMapSequence<AsyncStream<(A, B)>, C>>(
            AsyncStream<(A, B)>.zip(wa.value, wb.value).map { fn($0.0, $0.1) },
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, AsyncStream>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightWriterAsyncStream<W: Monoid, A, B>(
    _ lhs: Writer<W, AsyncStream<A>>,
    _ rhs: Writer<W, AsyncStream<B>>
) -> Writer<W, AsyncMapSequence<AsyncStream<(A, B)>, B>>
where A: Sendable, B: Sendable {
    liftA2WriterAsyncStream { @Sendable (_: A, b: B) in b }(lhs, rhs)
}

/// seqLeft for Writer<W, AsyncStream>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftWriterAsyncStream<W: Monoid, A, B>(
    _ lhs: Writer<W, AsyncStream<A>>,
    _ rhs: Writer<W, AsyncStream<B>>
) -> Writer<W, AsyncMapSequence<AsyncStream<(A, B)>, A>>
where A: Sendable, B: Sendable {
    liftA2WriterAsyncStream { @Sendable (a: A, _: B) in a }(lhs, rhs)
}
