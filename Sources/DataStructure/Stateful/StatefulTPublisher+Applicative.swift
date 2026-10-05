// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    // StatefulT + Publisher — free functions for Stateful<S, any Publisher<A, E>>
    //
    // Both state effects run in left-to-right order; the inner layer uses the Publisher applicative
    // (`ap`, cartesian, derived from the ordered-concat bind), not zip.

    /// liftA2 for Stateful<S, Publisher>
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func liftA2StatefulPublisher<S, A, B, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (Stateful<S, any Publisher<A, E>>, Stateful<S, any Publisher<B, E>>) -> Stateful<S, any Publisher<C, E>> {
        { sa, sb in
            Stateful<S, any Publisher<C, E>> { s in
                let publisherA = sa.run(&s)
                let publisherB = sb.run(&s)
                return AnyPublisher<C, E>.liftA2(fn)(publisherA, publisherB)
            }
        }
    }

    /// seqRight for Stateful<S, Publisher>
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func seqRightStatefulPublisher<S, A, B, E: Error>(
        _ lhs: Stateful<S, any Publisher<A, E>>,
        _ rhs: Stateful<S, any Publisher<B, E>>
    ) -> Stateful<S, any Publisher<B, E>> {
        Stateful<S, any Publisher<B, E>> { s in
            let left = lhs.run(&s)
            let right = rhs.run(&s)
            return AnyPublisher<B, E>.seqRight(left, right)
        }
    }

    /// seqLeft for Stateful<S, Publisher>
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func seqLeftStatefulPublisher<S, A, B, E: Error>(
        _ lhs: Stateful<S, any Publisher<A, E>>,
        _ rhs: Stateful<S, any Publisher<B, E>>
    ) -> Stateful<S, any Publisher<A, E>> {
        Stateful<S, any Publisher<A, E>> { s in
            let left = lhs.run(&s)
            let right = rhs.run(&s)
            return AnyPublisher<A, E>.seqLeft(left, right)
        }
    }

#endif
