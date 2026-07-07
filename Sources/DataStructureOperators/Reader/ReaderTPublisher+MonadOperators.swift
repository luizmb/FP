// SPDX-License-Identifier: Apache-2.0
import DataStructure
#if canImport(Combine)
    import Combine
    import CoreFPOperators

    // MARK: - ReaderT + Publisher

    // (>>-) :: m a -> (a -> m b) -> m b
    /// `>>-` overload for `ReaderT + Publisher`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func >>- <Env, A, B, E: Error>(
        _ reader: Reader<Env, any Publisher<A, E>>,
        _ fn: @escaping @Sendable (A) -> Reader<Env, any Publisher<B, E>>
    ) -> Reader<Env, any Publisher<B, E>> {
        reader.flatMapT(fn)
    }

    // (-<<) :: (a -> m b) -> m a -> m b
    /// `-` overload for `ReaderT + Publisher`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func -<< <Env, A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> Reader<Env, any Publisher<B, E>>,
        _ reader: Reader<Env, any Publisher<A, E>>
    ) -> Reader<Env, any Publisher<B, E>> {
        reader.flatMapT(fn)
    }

    // (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    /// `>=>` overload for `ReaderT + Publisher`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func >=> <Env, A, B, C, E: Error>(
        _ fn1: @escaping @Sendable (A) -> Reader<Env, any Publisher<B, E>>,
        _ fn2: @escaping @Sendable (B) -> Reader<Env, any Publisher<C, E>>
    ) -> (A) -> Reader<Env, any Publisher<C, E>> {
        kleisliT(fn1, fn2)
    }

#endif
