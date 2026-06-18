// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Writer<w, any Publisher<a, e>> -> Writer<w, any Publisher<b, e>>
/// `func`.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <£^> <W: Monoid, A: Sendable, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, any Publisher<A, E>>
) -> Writer<W, any Publisher<B, E>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, any Publisher<a, e>> -> (a -> b) -> Writer<w, any Publisher<b, e>>
/// `func`.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <&^> <W: Monoid, A: Sendable, B, E: Error>(
    _ writer: Writer<W, any Publisher<A, E>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Writer<W, any Publisher<B, E>> {
    writer.mapT(fn)
}

#endif
