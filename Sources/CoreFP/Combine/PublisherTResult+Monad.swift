// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTResult: outer = AnyPublisher, inner = Result
    // Type: AnyPublisher<Result<A,E2>, E>

    /// flatMapT for AnyPublisher<Result<A,E2>, E>
    /// .failure(e) → emit .failure(e)
    /// .success(a) → apply fn, concatenated in upstream order (ordered, lossless; see `concatMap`)
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func flatMapTPublisherResult<A, B, E: Error, E2: Error>(
        _ publisher: AnyPublisher<Result<A, E2>, E>,
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<B, E2>, E> {
        bindPublisherResult(publisher, fn)
    }

    /// The bind behind `flatMapTPublisherResult`, also used by the bind-derived applicative,
    /// whose continuation captures a (non-`Sendable`) publisher.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func bindPublisherResult<A, B, E: Error, E2: Error>(
        _ publisher: AnyPublisher<Result<A, E2>, E>,
        _ fn: @escaping (A) -> AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<B, E2>, E> {
        publisher.concatMap { result -> AnyPublisher<Result<B, E2>, E> in
            switch result {
            case let .failure(e2):
                Just(.failure(e2)).setFailureType(to: E.self).eraseToAnyPublisher()

            case let .success(a):
                fn(a)
            }
        }
    }

    /// `bindTPublisherResult`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func bindTPublisherResult<A, B, E: Error, E2: Error>(
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Result<B, E2>, E>
    ) -> @Sendable (AnyPublisher<Result<A, E2>, E>) -> AnyPublisher<Result<B, E2>, E> {
        { publisher in flatMapTPublisherResult(publisher, fn) }
    }

    /// Kleisli composition for `PublisherT + Result` (left-to-right)
    /// (>=>) :: (a -> Publisher<Result<b, e2>, e>) -> (b -> Publisher<Result<c, e2>, e>) -> a -> Publisher<Result<c, e2>, e>
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func kleisliT<A, B, C, E: Error, E2: Error>(
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<Result<B, E2>, E>,
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<Result<C, E2>, E>
    ) -> @Sendable (A) -> AnyPublisher<Result<C, E2>, E> {
        { a in flatMapTPublisherResult(fn1(a), fn2) }
    }

#endif
