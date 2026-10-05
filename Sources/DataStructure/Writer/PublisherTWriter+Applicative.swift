// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    // PublisherTWriter: outer = AnyPublisher, inner = Writer
    // Type: AnyPublisher<Writer<W, A>, E>
    // Haskell: WriterT w (Publisher e)
    //
    // The applicative is derived from the full-stack bind (`<*>` = `ap`): for each element of the left
    // stream, in order, the whole right stream runs, and every emitted log is `wLeft <> wRight`.

    /// apply for PublisherTWriter
    /// mf <*> ma = mf >>= \f -> fmap f ma
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func applyPublisherWriter<W: Monoid, A, B, E: Error>(
        _ fns: AnyPublisher<Writer<W, @Sendable (A) -> B>, E>,
        _ values: AnyPublisher<Writer<W, A>, E>
    ) -> AnyPublisher<Writer<W, B>, E> {
        fns.bindWriterT { f in values.mapT(f) }
    }

    /// liftA2 for PublisherTWriter
    /// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func liftA2PublisherWriter<W: Monoid, A: Sendable, B, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<Writer<W, A>, E>, AnyPublisher<Writer<W, B>, E>) -> AnyPublisher<Writer<W, C>, E> {
        { pubA, pubB in
            pubA.bindWriterT { a in pubB.mapT { b in fn(a, b) } }
        }
    }

    /// seqRight for PublisherTWriter
    /// ma *> mb = ma >>= \_ -> mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func seqRightPublisherWriter<W: Monoid, A, B, E: Error>(
        _ lhs: AnyPublisher<Writer<W, A>, E>,
        _ rhs: AnyPublisher<Writer<W, B>, E>
    ) -> AnyPublisher<Writer<W, B>, E> {
        lhs.bindWriterT { (_: A) in rhs }
    }

    /// seqLeft for PublisherTWriter
    /// ma <* mb = ma >>= \a -> fmap (const a) mb
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func seqLeftPublisherWriter<W: Monoid, A: Sendable, B, E: Error>(
        _ lhs: AnyPublisher<Writer<W, A>, E>,
        _ rhs: AnyPublisher<Writer<W, B>, E>
    ) -> AnyPublisher<Writer<W, A>, E> {
        lhs.bindWriterT { a in rhs.mapT { (_: B) in a } }
    }

#endif
