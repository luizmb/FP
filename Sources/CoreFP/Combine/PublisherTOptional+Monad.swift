#if canImport(Combine)
import Combine
import Foundation

// PublisherTOptional: outer = AnyPublisher, inner = Optional
// Type: AnyPublisher<A?, E>
// Haskell: MaybeT (Publisher e)

/// flatMapT for AnyPublisher<A?, E>
/// .none elements → emit .none
/// .some(a) elements → apply fn, flatten into publisher
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTPublisherOptional<A, B, E: Error>(
    _ publisher: AnyPublisher<A?, E>,
    _ fn: @escaping @Sendable (A) -> AnyPublisher<B?, E>
) -> AnyPublisher<B?, E> {
    publisher
        .flatMap { optA -> AnyPublisher<B?, E> in
            optA.map(fn) ?? Just(.none).setFailureType(to: E.self).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
}

/// Curried version
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTPublisherOptional<A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> AnyPublisher<B?, E>
) -> (AnyPublisher<A?, E>) -> AnyPublisher<B?, E> {
    { publisher in flatMapTPublisherOptional(publisher, fn) }
}

#endif
