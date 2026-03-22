#if canImport(Combine)
import Foundation
import CoreFP
import Combine

// WriterT + Publisher — free functions for Writer<W, any Publisher<A, E>>

/// apply for Writer<W, Publisher>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func applyWriterPublisher<W: Monoid, A, B, E: Error>(
    _ wf: Writer<W, any Publisher<(A) -> B, E>>,
    _ wa: Writer<W, any Publisher<A, E>>
) -> Writer<W, any Publisher<B, E>> {
    let publisherF = wf.value.eraseToAnyPublisher()
    let publisherA = wa.value.eraseToAnyPublisher()
    return Writer<W, any Publisher<B, E>>(
        publisherF.zip(publisherA).map { fn, a in fn(a) }.eraseToAnyPublisher(),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, Publisher>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func liftA2WriterPublisher<W: Monoid, A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (Writer<W, any Publisher<A, E>>, Writer<W, any Publisher<B, E>>) -> Writer<W, any Publisher<C, E>> {
    { wa, wb in
        Writer<W, any Publisher<C, E>>(
            wa.value.eraseToAnyPublisher().zip(wb.value.eraseToAnyPublisher()).map(fn).eraseToAnyPublisher(),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, Publisher>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func seqRightWriterPublisher<W: Monoid, A, B, E: Error>(
    _ lhs: Writer<W, any Publisher<A, E>>,
    _ rhs: Writer<W, any Publisher<B, E>>
) -> Writer<W, any Publisher<B, E>> {
    Writer<W, any Publisher<B, E>>(
        lhs.value.eraseToAnyPublisher().zip(rhs.value.eraseToAnyPublisher()).map(\.1).eraseToAnyPublisher(),
        W.combine(lhs.log, rhs.log)
    )
}

/// seqLeft for Writer<W, Publisher>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func seqLeftWriterPublisher<W: Monoid, A, B, E: Error>(
    _ lhs: Writer<W, any Publisher<A, E>>,
    _ rhs: Writer<W, any Publisher<B, E>>
) -> Writer<W, any Publisher<A, E>> {
    Writer<W, any Publisher<A, E>>(
        lhs.value.eraseToAnyPublisher().zip(rhs.value.eraseToAnyPublisher()).map(\.0).eraseToAnyPublisher(),
        W.combine(lhs.log, rhs.log)
    )
}

#endif
