#if canImport(Combine)
import Foundation
import CoreFP
import Combine

public extension Writer {
    // WriterT + Publisher — Writer<W, any Publisher<A, E>>
    //
    // flatMapT keeps the outer log and sequences the publishers.
    // Inner logs produced by fn are discarded — the publisher timeline is inherently
    // sequential but fn's log contributions can't be eagerly accumulated across events.
    // For log-accumulating pipelines prefer Writer<W, [A]> or Writer<W, Result<A,E>>.

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func flatMapT<Inner, B, E: Error>(
        _ fn: @escaping (Inner) -> Writer<W, any Publisher<B, E>>
    ) -> Writer<W, any Publisher<B, E>>
    where A == any Publisher<Inner, E> {
        Writer<W, any Publisher<B, E>>(
            value.eraseToAnyPublisher().flatMap { a in
                fn(a).value.eraseToAnyPublisher()
            }.eraseToAnyPublisher(),
            log
        )
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func bindT<Inner, B, E: Error>(
        _ fn: @escaping (Inner) -> Writer<W, any Publisher<B, E>>
    ) -> (Writer<W, any Publisher<Inner, E>>) -> Writer<W, any Publisher<B, E>>
    where A == any Publisher<Inner, E> {
        { $0.flatMapT(fn) }
    }
}

#endif
