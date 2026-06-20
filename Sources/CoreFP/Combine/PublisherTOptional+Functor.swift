// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTOptional: outer = AnyPublisher, inner = Optional
    // Type: AnyPublisher<A?, E>

    /// mapT for AnyPublisher<A?, E> — maps over the inner Optional's value
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func mapTPublisherOptional<A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> B,
        _ publisher: AnyPublisher<A?, E>
    ) -> AnyPublisher<B?, E> {
        publisher.map { optA in optA.map(fn) }.eraseToAnyPublisher()
    }

    /// Curried fmapT
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func fmapTPublisherOptional<A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> (AnyPublisher<A?, E>) -> AnyPublisher<B?, E> {
        { publisher in mapTPublisherOptional(fn, publisher) }
    }

#endif
