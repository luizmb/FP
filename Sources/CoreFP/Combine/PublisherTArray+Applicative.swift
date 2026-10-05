// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTArray: outer = AnyPublisher, inner = Array
    // Type: AnyPublisher<[A], E>

    /// `liftA2PublisherArray`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func liftA2PublisherArray<A, B, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<[A], E>, AnyPublisher<[B], E>) -> AnyPublisher<[C], E> {
        { pubA, pubB in
            pubA.concatMap { a in
                pubB.map { b in Array.liftA2(fn)(a, b) }
            }
        }
    }

    /// `seqRightPublisherArray`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func seqRightPublisherArray<A, B, E: Error>(
        _ lhs: AnyPublisher<[A], E>,
        _ rhs: AnyPublisher<[B], E>
    ) -> AnyPublisher<[B], E> {
        lhs.concatMap { a in
            rhs.map { b in a.seqRight(b) }
        }
    }

    /// `seqLeftPublisherArray`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func seqLeftPublisherArray<A, B, E: Error>(
        _ lhs: AnyPublisher<[A], E>,
        _ rhs: AnyPublisher<[B], E>
    ) -> AnyPublisher<[A], E> {
        lhs.concatMap { a in
            rhs.map { b in a.seqLeft(b) }
        }
    }

#endif
