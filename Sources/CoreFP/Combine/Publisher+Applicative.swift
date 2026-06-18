// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// liftA2 :: (a1 -> a2 -> a) -> Publisher<a1, e> -> Publisher<a2, e> -> Publisher<a, e>
    static func liftA2<A1, A2>(_ fn: @escaping @Sendable (A1, A2) -> A) -> @Sendable (
        any Publisher<A1, B>, any Publisher<A2, B>
    ) -> any Publisher<A, B> {
        { publisherA, publisherB in
            publisherA
                .eraseToAnyPublisher()
                .zip(publisherB.eraseToAnyPublisher())
                .map(fn)
        }
    }

    /// apply :: Publisher<(a -> b), e> -> Publisher<a, e> -> Publisher<b, e>
    static func apply<A0>(_ functions: any Publisher<(A0) -> A, B>, _ values: any Publisher<A0, B>) -> any Publisher<A, B> {
        functions.eraseToAnyPublisher()
            .zip(values.eraseToAnyPublisher())
            .map { fn, a in fn(a) }
    }

    /// seqRight :: Publisher<a, e> -> Publisher<b, e> -> Publisher<b, e>
    static func seqRight<A0>(_ lhs: any Publisher<A0, B>, _ rhs: any Publisher<A, B>) -> any Publisher<A, B> {
        lhs.eraseToAnyPublisher()
            .zip(rhs.eraseToAnyPublisher())
            .map(\.1)
    }

    /// seqLeft :: Publisher<a, e> -> Publisher<b, e> -> Publisher<a, e>
    static func seqLeft<A0>(_ lhs: any Publisher<A, B>, _ rhs: any Publisher<A0, B>) -> any Publisher<A, B> {
        lhs.eraseToAnyPublisher()
            .zip(rhs.eraseToAnyPublisher())
            .map(\.0)
    }

    /// The `property` property.
    static func zip<A1, A2>(_ lhs: any Publisher<A1, B>, _ rhs: any Publisher<A2, B>) -> any Publisher<A, B>
    where A == (A1, A2) {
        Publishers.Zip(lhs.eraseToAnyPublisher(), rhs.eraseToAnyPublisher())
    }
}

#endif
