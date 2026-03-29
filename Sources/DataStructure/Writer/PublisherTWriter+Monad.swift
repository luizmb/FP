#if canImport(Combine)
import Combine
import CoreFP
import Foundation

// PublisherTWriter: outer = Publisher, inner = Writer
// Type: AnyPublisher<Writer<W, A>, E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// flatMapT :: Publisher<Writer<w, a>, e> -> (a -> Writer<w, b>) -> Publisher<Writer<w, b>, e>
    func flatMapT<W: Monoid, A, B>(_ fn: @escaping (A) -> Writer<W, B>) -> AnyPublisher<Writer<W, B>, Failure>
    where Output == Writer<W, A> {
        map { writer in writer.flatMap(fn) }.eraseToAnyPublisher()
    }

    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping (A) -> Writer<W, B>
    ) -> (AnyPublisher<Writer<W, A>, Failure>) -> AnyPublisher<Writer<W, B>, Failure> {
        { publisher in publisher.flatMapT(fn) }
    }
}

#endif
