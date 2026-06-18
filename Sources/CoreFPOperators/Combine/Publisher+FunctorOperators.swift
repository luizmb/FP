// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
import CoreFP
import Foundation

// (<$>) :: Functor f => (a -> b) -> f a -> f b
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <A1, A, B: Error>(
    _ transform: @escaping @Sendable (A) -> A1,
    _ publisher: any Publisher<A, B>
) -> any Publisher<A1, B>
where B: Sendable, A1: Sendable, A: Sendable {
    AnyPublisher<A, B>.fmap(transform)(publisher)
}

// ($>) :: Publisher<a, e> -> b -> Publisher<b, e>
/// `£>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func £> <A1: Sendable, A: Sendable, B: Error & Sendable>(_ publisher: any Publisher<A, B>, _ value: A1) -> any Publisher<A1, B> {
    AnyPublisher<A, B>.fmap(const(value))(publisher)
}

// (<$) :: b -> Publisher<a, e> -> Publisher<b, e>
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£ <A1: Sendable, A: Sendable, B: Error & Sendable>(_ value: A1, _ publisher: any Publisher<A, B>) -> any Publisher<A1, B> {
    publisher £> value
}

#endif
