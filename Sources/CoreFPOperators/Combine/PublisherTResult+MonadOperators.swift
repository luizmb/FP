// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP

    // PublisherTResult: AnyPublisher<Result<A,E2>, E>

    // (>>-) :: AnyPublisher<Result<a,e2>,e> -> (a -> AnyPublisher<Result<b,e2>,e>) -> AnyPublisher<Result<b,e2>,e>
    /// `>>-` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func >>- <A, B, E: Error, E2: Error>(
        _ pub: AnyPublisher<Result<A, E2>, E>,
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<B, E2>, E> {
        flatMapTPublisherResult(pub, fn)
    }

    // (-<<) :: (a -> AnyPublisher<Result<b,e2>,e>) -> AnyPublisher<Result<a,e2>,e> -> AnyPublisher<Result<b,e2>,e>
    /// `-` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func -<< <A, B, E: Error, E2: Error>(
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Result<B, E2>, E>,
        _ pub: AnyPublisher<Result<A, E2>, E>
    ) -> AnyPublisher<Result<B, E2>, E> {
        flatMapTPublisherResult(pub, fn)
    }

    // (>=>) :: (a -> AnyPublisher<Result<b,e2>,e>) -> (b -> AnyPublisher<Result<c,e2>,e>) -> a -> AnyPublisher<Result<c,e2>,e>
    /// `>=>` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func >=> <A, B, C, E: Error, E2: Error>(
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<Result<B, E2>, E>,
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<Result<C, E2>, E>
    ) -> @Sendable (A) -> AnyPublisher<Result<C, E2>, E> {
        kleisliT(fn1, fn2)
    }
#endif
