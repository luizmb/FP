// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    // PublisherTEither: outer = AnyPublisher, inner = Either
    // Type: AnyPublisher<Either<L,A>, E>
    // Haskell: ExceptT l (Publisher e)

    /// flatMapT for AnyPublisher<Either<L,A>, E>
    /// .left(l)  → emit .left(l)
    /// .right(a) → fn(a), concatenated in upstream order (ordered, lossless; see `concatMap`)
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func flatMapTPublisherEither<L, A, B, E: Error>(
        _ publisher: AnyPublisher<Either<L, A>, E>,
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Either<L, B>, E>
    ) -> AnyPublisher<Either<L, B>, E> {
        bindPublisherEither(publisher, fn)
    }

    /// The bind behind `flatMapTPublisherEither`, also used by the bind-derived applicative,
    /// whose continuation captures a (non-`Sendable`) publisher.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func bindPublisherEither<L, A, B, E: Error>(
        _ publisher: AnyPublisher<Either<L, A>, E>,
        _ fn: @escaping (A) -> AnyPublisher<Either<L, B>, E>
    ) -> AnyPublisher<Either<L, B>, E> {
        publisher.concatMap { either -> AnyPublisher<Either<L, B>, E> in
            switch either {
            case let .left(l):
                Just(.left(l)).setFailureType(to: E.self).eraseToAnyPublisher()

            case let .right(a):
                fn(a)
            }
        }
    }

    /// `bindTPublisherEither`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func bindTPublisherEither<L, A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Either<L, B>, E>
    ) -> @Sendable (AnyPublisher<Either<L, A>, E>) -> AnyPublisher<Either<L, B>, E> {
        { publisher in flatMapTPublisherEither(publisher, fn) }
    }

    /// Kleisli composition for `PublisherT + Either` (left-to-right)
    /// (>=>) :: (a -> Publisher<Either<l, b>, e>) -> (b -> Publisher<Either<l, c>, e>) -> a -> Publisher<Either<l, c>, e>
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func kleisliT<L, A, B, C, E: Error>(
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<Either<L, B>, E>,
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<Either<L, C>, E>
    ) -> @Sendable (A) -> AnyPublisher<Either<L, C>, E> {
        { a in flatMapTPublisherEither(fn1(a), fn2) }
    }

#endif
