// SPDX-License-Identifier: Apache-2.0
import DataStructure
#if canImport(Combine)
    import Combine
    import CoreFPOperators
    import Foundation

    // ReaderT + Publisher

    // (<$>) :: Functor f => (a -> b) -> f a -> f b
    /// `func`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <£^> <A: Sendable, B: Sendable, E: Error, Env: Sendable>(
        _ transform: @escaping @Sendable (A) -> B,
        _ reader: Reader<Env, any Publisher<A, E>>
    ) -> Reader<Env, any Publisher<B, E>> {
        reader.mapT(transform)
    }

    // ($>) :: Either a b -> a0 -> Either a a0
    /// `£>` overload.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func £> <A1: Sendable, A: Sendable, B: Error, Env: Sendable>(
        _ reader: Reader<Env, any Publisher<A, B>>,
        _ value: A1
    ) -> Reader<Env, any Publisher<A1, B>> {
        reader.replaceOutputT(value)
    }

    // (<$) :: a0 -> Either a b -> Either a a0
    /// `func`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <£ <A1: Sendable, A: Sendable, B: Error, Env: Sendable>(
        _ value: A1,
        _ reader: Reader<Env, any Publisher<A, B>>
    ) -> Reader<Env, any Publisher<A1, B>> {
        reader £> value
    }

    // (<&^>) :: f (g a) -> (a -> b) -> f (g b)
    /// `func`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <&^> <A: Sendable, B: Sendable, E: Error, Env: Sendable>(
        _ reader: Reader<Env, any Publisher<A, E>>,
        _ transform: @escaping @Sendable (A) -> B
    ) -> Reader<Env, any Publisher<B, E>> {
        transform <£^> reader
    }

#endif
