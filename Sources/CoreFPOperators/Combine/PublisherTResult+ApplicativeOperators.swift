// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP

    // PublisherTResult: AnyPublisher<Result<A,E2>, E>

    // (*>) :: AnyPublisher<Result<a,e2>,e> -> AnyPublisher<Result<b,e2>,e> -> AnyPublisher<Result<b,e2>,e>
    /// `*>` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func *> <A, B, E: Error, E2: Error>(
        _ lhs: AnyPublisher<Result<A, E2>, E>,
        _ rhs: AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<B, E2>, E> {
        seqRightPublisherResult(lhs, rhs)
    }

    // (<*) :: AnyPublisher<Result<a,e2>,e> -> AnyPublisher<Result<b,e2>,e> -> AnyPublisher<Result<a,e2>,e>
    /// `func`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func <* <A, B, E: Error, E2: Error>(
        _ lhs: AnyPublisher<Result<A, E2>, E>,
        _ rhs: AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<A, E2>, E> {
        seqLeftPublisherResult(lhs, rhs)
    }
#endif
