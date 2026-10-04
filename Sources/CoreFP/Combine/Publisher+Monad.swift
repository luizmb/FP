// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // Publisher follows Haskell stream semantics (pipes / conduit / fs2):
    // bind is ordered concatenation. Each inner publisher runs to completion, in upstream order,
    // before the next one is subscribed, and no upstream value is dropped.

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public extension Publisher {
        /// Ordered, lossless concat-map: the monadic bind of `Publisher`.
        ///
        /// Each inner publisher runs to completion before the next upstream value is mapped, so the
        /// output is the concatenation of the inner streams in upstream order. Upstream values that
        /// arrive while an inner publisher is still running are buffered (unbounded), never dropped,
        /// even when the upstream ignores demand (e.g. `PassthroughSubject`).
        ///
        /// Use Combine's `flatMap` for merge semantics, or `map(_:).switchToLatest()` for latest.
        func concatMap<P: Publisher>(
            _ fn: @escaping (Output) -> P
        ) -> AnyPublisher<P.Output, Failure>
        where P.Failure == Failure {
            buffer(size: .max, prefetch: .keepFull, whenFull: .dropNewest)
                .flatMap(maxPublishers: .max(1), fn)
                .eraseToAnyPublisher()
        }

        /// Curried monadic bind (ordered concat, see ``concatMap(_:)``)
        /// (>>=) :: m a -> (a -> m b) -> m b
        static func bind<A1, P: Publisher>(
            _ fn: @escaping @Sendable (A) -> P
        ) -> @Sendable (any Publisher<A, Failure>) -> any Publisher<A1, Failure>
        where P.Output == A1, P.Failure == Failure {
            { publisher in
                publisher.eraseToAnyPublisher().concatMap(fn)
            }
        }

        /// Kleisli composition (left-to-right), using the ordered-concat bind
        /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
        static func kleisli<A0, A1, P1: Publisher, P2: Publisher>(
            _ fn1: @escaping @Sendable (A0) -> P1,
            _ fn2: @escaping @Sendable (A) -> P2
        ) -> @Sendable (A0) -> any Publisher<A1, Failure>
        where P1.Output == A, P1.Failure == Failure, P2.Output == A1, P2.Failure == Failure {
            { a0 in
                fn1(a0).eraseToAnyPublisher().concatMap(fn2)
            }
        }

        /// Kleisli composition (right-to-left), using the ordered-concat bind
        /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
        static func kleisliBack<A0, A1, P1: Publisher, P2: Publisher>(
            _ fn2: @escaping @Sendable (A) -> P2,
            _ fn1: @escaping @Sendable (A0) -> P1
        ) -> @Sendable (A0) -> any Publisher<A1, Failure>
        where P1.Output == A, P1.Failure == Failure, P2.Output == A1, P2.Failure == Failure {
            kleisli(fn1, fn2)
        }
    }

#endif
