#if canImport(Combine)
import Foundation
import CoreFP
import Combine

// PublisherTStateful: outer = Publisher, inner = Stateful
// Type: AnyPublisher<Stateful<S, A>, E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// flatMapT :: Publisher<Stateful<s, a>, e> -> (a -> Stateful<s, b>) -> Publisher<Stateful<s, b>, e>
    func flatMapT<S, A, B>(_ fn: @escaping (A) -> Stateful<S, B>) -> AnyPublisher<Stateful<S, B>, Failure>
    where Output == Stateful<S, A> {
        map { stateful in stateful.flatMap(fn) }.eraseToAnyPublisher()
    }

    static func bindT<S, A, B>(
        _ fn: @escaping (A) -> Stateful<S, B>
    ) -> (AnyPublisher<Stateful<S, A>, Failure>) -> AnyPublisher<Stateful<S, B>, Failure> {
        { publisher in publisher.flatMapT(fn) }
    }
}

#endif
