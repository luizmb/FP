#if canImport(Combine)
import Combine
import CoreFP
import Foundation

// PublisherTStateful: outer = Publisher, inner = Stateful
// Type: AnyPublisher<Stateful<S, A>, E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    func mapT<S, A, B>(_ fn: @escaping (A) -> B) -> AnyPublisher<Stateful<S, B>, Failure>
    where Output == Stateful<S, A> {
        map { stateful in stateful.fmap(fn) }.eraseToAnyPublisher()
    }

    static func fmapT<S, A, B>(
        _ fn: @escaping (A) -> B
    ) -> (AnyPublisher<Stateful<S, A>, Failure>) -> AnyPublisher<Stateful<S, B>, Failure> {
        { publisher in publisher.mapT(fn) }
    }
}

#endif
