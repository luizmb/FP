// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import CoreFPOperators
    import DataStructure

    // (>>-) :: AnyPublisher<Writer<w, a>, e> -> (a -> AnyPublisher<Writer<w, b>, e>) -> AnyPublisher<Writer<w, b>, e>
    /// `>>-` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func >>- <W: Monoid, A, B, E: Error>(
        _ publisher: AnyPublisher<Writer<W, A>, E>,
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Writer<W, B>, E>
    ) -> AnyPublisher<Writer<W, B>, E> {
        publisher.flatMapT(fn)
    }

    // (-<<) :: (a -> AnyPublisher<Writer<w, b>, e>) -> AnyPublisher<Writer<w, a>, e> -> AnyPublisher<Writer<w, b>, e>
    /// `-<<` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func -<< <W: Monoid, A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> AnyPublisher<Writer<W, B>, E>,
        _ publisher: AnyPublisher<Writer<W, A>, E>
    ) -> AnyPublisher<Writer<W, B>, E> {
        publisher.flatMapT(fn)
    }

    // (>=>) :: (a -> AnyPublisher<Writer<w, b>, e>) -> (b -> AnyPublisher<Writer<w, c>, e>) -> a -> AnyPublisher<Writer<w, c>, e>
    /// `>=>` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func >=> <W: Monoid, A, B, C, E: Error>(
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<Writer<W, B>, E>,
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<Writer<W, C>, E>
    ) -> @Sendable (A) -> AnyPublisher<Writer<W, C>, E> {
        kleisliT(fn1, fn2)
    }

#endif
