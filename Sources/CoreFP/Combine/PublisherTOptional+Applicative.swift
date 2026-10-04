// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTOptional: outer = AnyPublisher, inner = Optional
    // Type: AnyPublisher<A?, E>
    // Haskell: MaybeT (Publisher e)
    //
    // The applicative is derived from the monad (`<*>` = `ap`): sequential, ordered concat over the
    // stream, short-circuiting per element. A `.none` on the left emits a single `.none` and never
    // subscribes to the right side for that element.

    /// apply for PublisherTOptional
    /// mf <*> ma = mf >>= \f -> fmap f ma
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func applyPublisherOptional<A, B, E: Error>(
        _ fns: AnyPublisher<(@Sendable (A) -> B)?, E>,
        _ values: AnyPublisher<A?, E>
    ) -> AnyPublisher<B?, E> {
        bindPublisherOptional(fns) { f in values.mapT(f) }
    }

    /// liftA2 for PublisherTOptional
    /// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func liftA2PublisherOptional<A: Sendable, B, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<A?, E>, AnyPublisher<B?, E>) -> AnyPublisher<C?, E> {
        { pubA, pubB in
            bindPublisherOptional(pubA) { a in pubB.mapT { b in fn(a, b) } }
        }
    }

    /// seqRight for PublisherTOptional
    /// ma *> mb = ma >>= \_ -> mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqRightPublisherOptional<A, B, E: Error>(
        _ lhs: AnyPublisher<A?, E>,
        _ rhs: AnyPublisher<B?, E>
    ) -> AnyPublisher<B?, E> {
        bindPublisherOptional(lhs) { (_: A) in rhs }
    }

    /// seqLeft for PublisherTOptional
    /// ma <* mb = ma >>= \a -> fmap (const a) mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqLeftPublisherOptional<A: Sendable, B, E: Error>(
        _ lhs: AnyPublisher<A?, E>,
        _ rhs: AnyPublisher<B?, E>
    ) -> AnyPublisher<A?, E> {
        bindPublisherOptional(lhs) { a in rhs.mapT { (_: B) in a } }
    }

#endif
