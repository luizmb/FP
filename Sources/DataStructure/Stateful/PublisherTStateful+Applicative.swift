// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTStateful: outer = AnyPublisher, inner = Stateful
    // Type: AnyPublisher<Stateful<S, A>, E>

    /// liftA2 for PublisherTStateful
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func liftA2PublisherStateful<S, A, B, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<Stateful<S, A>, E>, AnyPublisher<Stateful<S, B>, E>) -> AnyPublisher<Stateful<S, C>, E> {
        { pubA, pubB in
            pubA.zip(pubB)
                .map { sa, sb in Stateful<S, C> { s in fn(sa.run(&s), sb.run(&s)) } }
                .eraseToAnyPublisher()
        }
    }

    /// seqRight for PublisherTStateful
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqRightPublisherStateful<S, A, B, E: Error>(
        _ lhs: AnyPublisher<Stateful<S, A>, E>,
        _ rhs: AnyPublisher<Stateful<S, B>, E>
    ) -> AnyPublisher<Stateful<S, B>, E> {
        lhs.zip(rhs)
            .map { sa, sb in sa.seqRight(sb) }
            .eraseToAnyPublisher()
    }

    /// seqLeft for PublisherTStateful
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqLeftPublisherStateful<S, A, B, E: Error>(
        _ lhs: AnyPublisher<Stateful<S, A>, E>,
        _ rhs: AnyPublisher<Stateful<S, B>, E>
    ) -> AnyPublisher<Stateful<S, A>, E> {
        lhs.zip(rhs)
            .map { sa, sb in sa.seqLeft(sb) }
            .eraseToAnyPublisher()
    }

#endif
