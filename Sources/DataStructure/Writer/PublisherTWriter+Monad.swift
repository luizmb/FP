// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    // PublisherTWriter: outer = Publisher, inner = Writer
    // Type: AnyPublisher<Writer<W, A>, E>
    // Haskell: WriterT w (Publisher e)
    //
    // Full-stack bind: the continuation returns the whole stack, its inner streams are concatenated
    // in upstream order (ordered, lossless; see `concatMap`), and each emitted log is `w1 <> w2`.

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public extension Publisher {
        /// flatMapT :: Publisher<Writer<w, a>, e> -> (a -> Publisher<Writer<w, b>, e>) -> Publisher<Writer<w, b>, e>
        func flatMapT<W: Monoid, A, B>(
            _ fn: @escaping @Sendable (A) -> AnyPublisher<Writer<W, B>, Failure>
        ) -> AnyPublisher<Writer<W, B>, Failure>
        where Output == Writer<W, A> {
            bindWriterT(fn)
        }

        /// The `flatMapT` bind, curried.
        static func bindT<W: Monoid, A, B>(
            _ fn: @escaping @Sendable (A) -> AnyPublisher<Writer<W, B>, Failure>
        ) -> @Sendable (AnyPublisher<Writer<W, A>, Failure>) -> AnyPublisher<Writer<W, B>, Failure> {
            { publisher in publisher.flatMapT(fn) }
        }

        /// The bind behind `flatMapT`, also used by the bind-derived applicative,
        /// whose continuation captures a (non-`Sendable`) publisher.
        internal func bindWriterT<W: Monoid, A, B>(
            _ fn: @escaping (A) -> AnyPublisher<Writer<W, B>, Failure>
        ) -> AnyPublisher<Writer<W, B>, Failure>
        where Output == Writer<W, A> {
            concatMap { wa in
                fn(wa.value).map { wb in Writer<W, B>(wb.value, W.combine(wa.log, wb.log)) }
            }
        }
    }

    /// Kleisli composition for `PublisherT + Writer` (left-to-right)
    /// (>=>) :: (a -> Publisher<Writer<w, b>, e>) -> (b -> Publisher<Writer<w, c>, e>) -> a -> Publisher<Writer<w, c>, e>
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func kleisliT<W: Monoid, A, B, C, E: Error>(
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<Writer<W, B>, E>,
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<Writer<W, C>, E>
    ) -> @Sendable (A) -> AnyPublisher<Writer<W, C>, E> {
        { a in fn1(a).flatMapT(fn2) }
    }

#endif
