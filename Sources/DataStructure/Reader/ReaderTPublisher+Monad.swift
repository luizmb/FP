// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    extension Reader {
        // MARK: - ReaderT + Publisher

        /// Monadic bind for ReaderT Publisher, using the Publisher ordered-concat bind
        /// (each inner stream runs to completion in upstream order; see `concatMap`)
        /// (>>=) :: m a -> (a -> m b) -> m b
        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        func flatMapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> Reader<Environment, any Publisher<B, E>>)
            -> Reader<Environment, any Publisher<B, E>>
            where Output == any Publisher<A, E> {
            Reader<Environment, any Publisher<B, E>> { env in
                self.runReader(env)
                    .eraseToAnyPublisher()
                    .concatMap { a in
                        fn(a).runReader(env).eraseToAnyPublisher()
                    }
            }
        }

        /// Curried bind for ReaderT Publisher
        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        static func bindT<A, B, E: Error>(
            _ fn: @escaping @Sendable (A) -> Reader<Environment, any Publisher<B, E>>
        ) -> @Sendable (Reader<Environment, any Publisher<A, E>>) -> Reader<Environment, any Publisher<B, E>>
        where Output == any Publisher<A, E> {
            { reader in
                reader.flatMapT(fn)
            }
        }
    }

    /// Kleisli composition for `ReaderT + Publisher` (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func kleisliT<Env, A, B, C, E: Error>(
        _ fn1: @escaping @Sendable (A) -> Reader<Env, any Publisher<B, E>>,
        _ fn2: @escaping @Sendable (B) -> Reader<Env, any Publisher<C, E>>
    ) -> @Sendable (A) -> Reader<Env, any Publisher<C, E>> {
        { a in fn1(a).flatMapT(fn2) }
    }

#endif
