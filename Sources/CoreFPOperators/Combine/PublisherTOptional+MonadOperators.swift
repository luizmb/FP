// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP

    // PublisherTOptional: AnyPublisher<A?, E>

    // (>>-) :: AnyPublisher<a?,e> -> (a -> AnyPublisher<b?,e>) -> AnyPublisher<b?,e>
    /// `>>-` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func >>- <A, B, E: Error>(
        _ pub: AnyPublisher<A?, E>,
        _ fn: @escaping @Sendable (A) -> AnyPublisher<B?, E>
    ) -> AnyPublisher<B?, E> {
        flatMapTPublisherOptional(pub, fn)
    }

    // (-<<) :: (a -> AnyPublisher<b?,e>) -> AnyPublisher<a?,e> -> AnyPublisher<b?,e>
    /// `-` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func -<< <A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> AnyPublisher<B?, E>,
        _ pub: AnyPublisher<A?, E>
    ) -> AnyPublisher<B?, E> {
        flatMapTPublisherOptional(pub, fn)
    }

    // (>=>) :: (a -> AnyPublisher<b?,e>) -> (b -> AnyPublisher<c?,e>) -> a -> AnyPublisher<c?,e>
    /// `>=>` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func >=> <A, B, C, E: Error>(
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<B?, E>,
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<C?, E>
    ) -> @Sendable (A) -> AnyPublisher<C?, E> {
        kleisliT(fn1, fn2)
    }
#endif
