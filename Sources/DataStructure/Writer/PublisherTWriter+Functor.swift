#if canImport(Combine)
import Foundation
import CoreFP
import Combine

// PublisherTWriter: outer = Publisher, inner = Writer
// Type: AnyPublisher<Writer<W, A>, E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    func mapT<W: Monoid, A, B>(_ fn: @escaping (A) -> B) -> AnyPublisher<Writer<W, B>, Failure>
    where Output == Writer<W, A> {
        map { writer in writer.fmap(fn) }.eraseToAnyPublisher()
    }

    static func fmapT<W: Monoid, A, B>(
        _ fn: @escaping (A) -> B
    ) -> (AnyPublisher<Writer<W, A>, Failure>) -> AnyPublisher<Writer<W, B>, Failure> {
        { publisher in publisher.mapT(fn) }
    }
}

#endif
