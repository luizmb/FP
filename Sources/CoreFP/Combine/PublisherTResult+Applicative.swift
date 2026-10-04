// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTResult: outer = AnyPublisher, inner = Result
    // Type: AnyPublisher<Result<A,E2>, E>
    // Haskell: ExceptT e2 (Publisher e)
    //
    // The applicative is derived from the monad (`<*>` = `ap`): sequential, ordered concat over the
    // stream, short-circuiting per element. A `.failure` on the left emits a single `.failure` and never
    // subscribes to the right side for that element.

    /// apply for PublisherTResult
    /// mf <*> ma = mf >>= \f -> fmap f ma
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func applyPublisherResult<A, B, E: Error, E2: Error>(
        _ fns: AnyPublisher<Result<@Sendable (A) -> B, E2>, E>,
        _ values: AnyPublisher<Result<A, E2>, E>
    ) -> AnyPublisher<Result<B, E2>, E> {
        bindPublisherResult(fns) { f in values.mapT(f) }
    }

    /// liftA2 for PublisherTResult
    /// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func liftA2PublisherResult<A: Sendable, B, C, E: Error, E2: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<Result<A, E2>, E>, AnyPublisher<Result<B, E2>, E>) -> AnyPublisher<Result<C, E2>, E> {
        { pubA, pubB in
            bindPublisherResult(pubA) { a in pubB.mapT { b in fn(a, b) } }
        }
    }

    /// seqRight for PublisherTResult
    /// ma *> mb = ma >>= \_ -> mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqRightPublisherResult<A, B, E: Error, E2: Error>(
        _ lhs: AnyPublisher<Result<A, E2>, E>,
        _ rhs: AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<B, E2>, E> {
        bindPublisherResult(lhs) { (_: A) in rhs }
    }

    /// seqLeft for PublisherTResult
    /// ma <* mb = ma >>= \a -> fmap (const a) mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqLeftPublisherResult<A: Sendable, B, E: Error, E2: Error>(
        _ lhs: AnyPublisher<Result<A, E2>, E>,
        _ rhs: AnyPublisher<Result<B, E2>, E>
    ) -> AnyPublisher<Result<A, E2>, E> {
        bindPublisherResult(lhs) { a in rhs.mapT { (_: B) in a } }
    }

#endif
