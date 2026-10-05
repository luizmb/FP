// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTStateful: outer = AnyPublisher, inner = Stateful
    // Type: AnyPublisher<Stateful<S, A>, E>

    /// liftA2 for PublisherTStateful
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func liftA2PublisherStateful<S, A, B, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<Stateful<S, A>, E>, AnyPublisher<Stateful<S, B>, E>) -> AnyPublisher<Stateful<S, C>, E> {
        { pubA, pubB in
            pubA.concatMap { sa in
                pubB.map { sb in Stateful<S, C> { s in fn(sa.run(&s), sb.run(&s)) } }
            }
        }
    }

    /// seqRight for PublisherTStateful
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func seqRightPublisherStateful<S, A, B, E: Error>(
        _ lhs: AnyPublisher<Stateful<S, A>, E>,
        _ rhs: AnyPublisher<Stateful<S, B>, E>
    ) -> AnyPublisher<Stateful<S, B>, E> {
        lhs.concatMap { sa in
            rhs.map { sb in sa.seqRight(sb) }
        }
    }

    /// seqLeft for PublisherTStateful
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func seqLeftPublisherStateful<S, A, B, E: Error>(
        _ lhs: AnyPublisher<Stateful<S, A>, E>,
        _ rhs: AnyPublisher<Stateful<S, B>, E>
    ) -> AnyPublisher<Stateful<S, A>, E> {
        lhs.concatMap { sa in
            rhs.map { sb in sa.seqLeft(sb) }
        }
    }

#endif
