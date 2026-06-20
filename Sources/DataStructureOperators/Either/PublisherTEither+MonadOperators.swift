// SPDX-License-Identifier: Apache-2.0
import DataStructure
#if canImport(Combine)
    import Combine
    import CoreFPOperators

    // PublisherTEither: AnyPublisher<Either<L,A>, E>

    /// `>>-` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func >>- <L, A, B, E: Error>(
        _ pub: AnyPublisher<Either<L, A>, E>,
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Either<L, B>, E>
    ) -> AnyPublisher<Either<L, B>, E> {
        flatMapTPublisherEither(pub, fn)
    }

    /// `-` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func -<< <L, A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Either<L, B>, E>,
        _ pub: AnyPublisher<Either<L, A>, E>
    ) -> AnyPublisher<Either<L, B>, E> {
        flatMapTPublisherEither(pub, fn)
    }
#endif
