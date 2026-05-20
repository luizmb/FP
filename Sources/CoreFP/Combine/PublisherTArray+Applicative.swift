#if canImport(Combine)
import Combine
import Foundation

// PublisherTArray: outer = AnyPublisher, inner = Array
// Type: AnyPublisher<[A], E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2PublisherArray<A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (AnyPublisher<[A], E>, AnyPublisher<[B], E>) -> AnyPublisher<[C], E> {
    { pubA, pubB in
        pubA.zip(pubB)
            .map { a, b in Array.liftA2(fn)(a, b) }
            .eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightPublisherArray<A, B, E: Error>(
    _ lhs: AnyPublisher<[A], E>,
    _ rhs: AnyPublisher<[B], E>
) -> AnyPublisher<[B], E> {
    lhs.zip(rhs)
        .map { a, b in a.seqRight(b) }
        .eraseToAnyPublisher()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftPublisherArray<A, B, E: Error>(
    _ lhs: AnyPublisher<[A], E>,
    _ rhs: AnyPublisher<[B], E>
) -> AnyPublisher<[A], E> {
    lhs.zip(rhs)
        .map { a, b in a.seqLeft(b) }
        .eraseToAnyPublisher()
}

#endif
