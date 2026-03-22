#if canImport(Combine)
import Combine
import Foundation

// PublisherTOptional: outer = AnyPublisher, inner = Optional
// Type: AnyPublisher<A?, E>

/// liftA2 for PublisherTOptional
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2PublisherOptional<A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (AnyPublisher<A?, E>, AnyPublisher<B?, E>) -> AnyPublisher<C?, E> {
    { pubA, pubB in
        pubA.zip(pubB)
            .map { a, b in Optional.liftA2(fn)(a, b) }
            .eraseToAnyPublisher()
    }
}

/// seqRight for PublisherTOptional
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightPublisherOptional<A, B, E: Error>(
    _ lhs: AnyPublisher<A?, E>,
    _ rhs: AnyPublisher<B?, E>
) -> AnyPublisher<B?, E> {
    lhs.zip(rhs)
        .map { a, b in a.seqRight(b) }
        .eraseToAnyPublisher()
}

/// seqLeft for PublisherTOptional
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftPublisherOptional<A, B, E: Error>(
    _ lhs: AnyPublisher<A?, E>,
    _ rhs: AnyPublisher<B?, E>
) -> AnyPublisher<A?, E> {
    lhs.zip(rhs)
        .map { a, b in a.seqLeft(b) }
        .eraseToAnyPublisher()
}

#endif
