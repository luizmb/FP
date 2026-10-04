// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    // (<*>) :: Publisher<(a -> b), e> -> Publisher<a, e> -> Publisher<b, e>
    // `ap` derived from the ordered-concat bind: `[f, g] <*> [1, 2]` emits `[f(1), f(2), g(1), g(2)]`
    /// `func`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func <*> <A0, A, B: Error>(_ lhs: any Publisher<@Sendable (A0) -> A, B>, _ rhs: any Publisher<A0, B>)
    -> any Publisher<A, B> {
        AnyPublisher<A, B>.apply(lhs, rhs)
    }

    // (*>) :: Publisher<ignore, e> -> Publisher<a, e> -> Publisher<a, e>
    /// `*>` overload.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func *> <A, Ignore, B: Error>(_ lhs: any Publisher<Ignore, B>, _ rhs: any Publisher<A, B>)
    -> any Publisher<A, B> {
        AnyPublisher<A, B>.seqRight(lhs, rhs)
    }

    // (<*) :: Publisher<a, e> -> Publisher<ignore, e> -> Publisher<a, e>
    /// `func`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func <* <A, B: Error, Ignore>(_ lhs: any Publisher<A, B>, _ rhs: any Publisher<Ignore, B>)
    -> any Publisher<A, B> {
        AnyPublisher<A, B>.seqLeft(lhs, rhs)
    }

#endif
