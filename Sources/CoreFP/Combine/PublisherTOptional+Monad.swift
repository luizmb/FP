// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTOptional: outer = AnyPublisher, inner = Optional
    // Type: AnyPublisher<A?, E>
    // Haskell: MaybeT (Publisher e)

    /// flatMapT for AnyPublisher<A?, E>
    /// .none elements → emit .none
    /// .some(a) elements → apply fn, concatenated in upstream order (ordered, lossless; see `concatMap`)
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func flatMapTPublisherOptional<A, B, E: Error>(
        _ publisher: AnyPublisher<A?, E>,
        _ fn: @escaping @Sendable (A) -> AnyPublisher<B?, E>
    ) -> AnyPublisher<B?, E> {
        bindPublisherOptional(publisher, fn)
    }

    /// The bind behind `flatMapTPublisherOptional`, also used by the bind-derived applicative,
    /// whose continuation captures a (non-`Sendable`) publisher.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func bindPublisherOptional<A, B, E: Error>(
        _ publisher: AnyPublisher<A?, E>,
        _ fn: @escaping (A) -> AnyPublisher<B?, E>
    ) -> AnyPublisher<B?, E> {
        publisher.concatMap { optA -> AnyPublisher<B?, E> in
            optA.map(fn) ?? Just(.none).setFailureType(to: E.self).eraseToAnyPublisher()
        }
    }

    /// Kleisli composition for `PublisherT + Optional` (left-to-right)
    /// (>=>) :: (a -> Publisher<b?, e>) -> (b -> Publisher<c?, e>) -> a -> Publisher<c?, e>
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func kleisliT<A, B, C, E: Error>(
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<B?, E>,
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<C?, E>
    ) -> @Sendable (A) -> AnyPublisher<C?, E> {
        { a in flatMapTPublisherOptional(fn1(a), fn2) }
    }

    /// Curried version
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func bindTPublisherOptional<A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> AnyPublisher<B?, E>
    ) -> @Sendable (AnyPublisher<A?, E>) -> AnyPublisher<B?, E> {
        { publisher in flatMapTPublisherOptional(publisher, fn) }
    }

#endif
