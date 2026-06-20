// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFPOperators
    import DataStructure

    // (<£^>) :: (a -> b) -> Stateful<s, any Publisher<a, e>> -> Stateful<s, any Publisher<b, e>>
    /// `func`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <£^> <S, A: Sendable, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> B,
        _ stateful: Stateful<S, any Publisher<A, E>>
    ) -> Stateful<S, any Publisher<B, E>> {
        stateful.mapT(fn)
    }

    // (<&^>) :: Stateful<s, any Publisher<a, e>> -> (a -> b) -> Stateful<s, any Publisher<b, e>>
    /// `func`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <&^> <S, A: Sendable, B, E: Error>(
        _ stateful: Stateful<S, any Publisher<A, E>>,
        _ fn: @escaping @Sendable (A) -> B
    ) -> Stateful<S, any Publisher<B, E>> {
        stateful.mapT(fn)
    }

#endif
