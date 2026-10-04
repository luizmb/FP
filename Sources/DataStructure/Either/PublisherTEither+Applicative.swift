// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTEither: outer = AnyPublisher, inner = Either
    // Type: AnyPublisher<Either<L,A>, E>
    // Haskell: ExceptT l (Publisher e)
    //
    // The applicative is derived from the monad (`<*>` = `ap`): sequential, ordered concat over the
    // stream, short-circuiting per element. A `.left` on the left emits a single `.left` and never
    // subscribes to the right side for that element.

    /// apply for PublisherTEither
    /// mf <*> ma = mf >>= \f -> fmap f ma
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func applyPublisherEither<L: Sendable, A: Sendable, B: Sendable, E: Error>(
        _ fns: AnyPublisher<Either<L, @Sendable (A) -> B>, E>,
        _ values: AnyPublisher<Either<L, A>, E>
    ) -> AnyPublisher<Either<L, B>, E> {
        bindPublisherEither(fns) { f in values.mapT(f) }
    }

    /// liftA2 for PublisherTEither
    /// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func liftA2PublisherEither<L: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<Either<L, A>, E>, AnyPublisher<Either<L, B>, E>) -> AnyPublisher<Either<L, C>, E> {
        { pubA, pubB in
            bindPublisherEither(pubA) { a in pubB.mapT { b in fn(a, b) } }
        }
    }

    /// seqRight for PublisherTEither
    /// ma *> mb = ma >>= \_ -> mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqRightPublisherEither<L: Sendable, A: Sendable, B: Sendable, E: Error>(
        _ lhs: AnyPublisher<Either<L, A>, E>,
        _ rhs: AnyPublisher<Either<L, B>, E>
    ) -> AnyPublisher<Either<L, B>, E> {
        bindPublisherEither(lhs) { (_: A) in rhs }
    }

    /// seqLeft for PublisherTEither
    /// ma <* mb = ma >>= \a -> fmap (const a) mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqLeftPublisherEither<L: Sendable, A: Sendable, B: Sendable, E: Error>(
        _ lhs: AnyPublisher<Either<L, A>, E>,
        _ rhs: AnyPublisher<Either<L, B>, E>
    ) -> AnyPublisher<Either<L, A>, E> {
        bindPublisherEither(lhs) { a in rhs.mapT { (_: B) in a } }
    }

#endif
