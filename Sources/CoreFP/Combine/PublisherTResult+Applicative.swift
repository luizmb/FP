// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTResult: outer = AnyPublisher, inner = Result
    // Type: AnyPublisher<Result<A,E2>, E>

    /// `liftA2PublisherResult`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func liftA2PublisherResult<A, B, C, E: Error, E2: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<Result<A, E2>, E>, AnyPublisher<Result<B, E2>, E>) -> AnyPublisher<Result<C, E2>, E> {
        { pubA, pubB in
            pubA.zip(pubB)
                .map { a, b in Result.liftA2(fn)(a, b) }
                .eraseToAnyPublisher()
        }
    }

    /// `seqRightPublisherResult`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqRightPublisherResult<A, B, E: Error, E2: Error>(
        _ lhs: AnyPublisher<Result<A, E2>, E>,
        _ rhs: AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<B, E2>, E> {
        lhs.zip(rhs)
            .map { a, b in a.seqRight(b) }
            .eraseToAnyPublisher()
    }

    /// `seqLeftPublisherResult`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqLeftPublisherResult<A, B, E: Error, E2: Error>(
        _ lhs: AnyPublisher<Result<A, E2>, E>,
        _ rhs: AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<A, E2>, E> {
        lhs.zip(rhs)
            .map { a, b in a.seqLeft(b) }
            .eraseToAnyPublisher()
    }

#endif
