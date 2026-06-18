// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP

    // PublisherTArray: AnyPublisher<[A], E>

    // (*>) :: AnyPublisher<[a],e> -> AnyPublisher<[b],e> -> AnyPublisher<[b],e>
    /// `*>` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func *> <A, B, E: Error>(_ lhs: AnyPublisher<[A], E>, _ rhs: AnyPublisher<[B], E>) -> AnyPublisher<[B], E> {
        seqRightPublisherArray(lhs, rhs)
    }

    // (<*) :: AnyPublisher<[a],e> -> AnyPublisher<[b],e> -> AnyPublisher<[a],e>
    /// `func`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func <* <A, B, E: Error>(_ lhs: AnyPublisher<[A], E>, _ rhs: AnyPublisher<[B], E>) -> AnyPublisher<[A], E> {
        seqLeftPublisherArray(lhs, rhs)
    }
#endif
