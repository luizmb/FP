// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import CoreFPOperators
    import DataStructure

    // (>>-) :: Writer<w, any Publisher<a, e>> -> (a -> Writer<w, any Publisher<b, e>>) -> Writer<w, any Publisher<b, e>>
    /// `>>-` overload.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func >>- <W: Monoid, A, B, E: Error>(
        _ writer: Writer<W, any Publisher<A, E>>,
        _ fn: @escaping @Sendable (A) -> Writer<W, any Publisher<B, E>>
    ) -> Writer<W, any Publisher<B, E>> {
        writer.flatMapT(fn)
    }

    // (-<<) :: (a -> Writer<w, any Publisher<b, e>>) -> Writer<w, any Publisher<a, e>> -> Writer<w, any Publisher<b, e>>
    /// `-` overload.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func -<< <W: Monoid, A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> Writer<W, any Publisher<B, E>>,
        _ writer: Writer<W, any Publisher<A, E>>
    ) -> Writer<W, any Publisher<B, E>> {
        writer.flatMapT(fn)
    }

    // (>=>) :: (a -> Writer<w, any Publisher<b, e>>) -> (b -> Writer<w, any Publisher<c, e>>) -> a -> Writer<w, any Publisher<c, e>>
    /// `>=>` overload.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func >=> <W: Monoid, A, B, C, E: Error>(
        _ fn1: @escaping @Sendable (A) -> Writer<W, any Publisher<B, E>>,
        _ fn2: @escaping @Sendable (B) -> Writer<W, any Publisher<C, E>>
    ) -> (A) -> Writer<W, any Publisher<C, E>> {
        kleisliT(fn1, fn2)
    }

#endif
