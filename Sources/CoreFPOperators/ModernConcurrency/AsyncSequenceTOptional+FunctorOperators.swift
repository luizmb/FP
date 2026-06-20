// SPDX-License-Identifier: Apache-2.0
import CoreFP

// AsyncSequenceTOptional: AsyncStream<A?>

// (<£^>) :: @Sendable (a -> b) -> AsyncStream<a?> -> AsyncStream<b?>
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <A, B: Sendable>(_ fn: @escaping @Sendable (A) -> B, _ stream: AsyncStream<A?>) -> AsyncStream<B?>
where A: Sendable {
    mapTAsyncStreamOptional(fn, stream)
}

// (<&^>) :: AsyncStream<a?> -> @Sendable (a -> b) -> AsyncStream<b?>
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <A, B: Sendable>(_ stream: AsyncStream<A?>, _ fn: @escaping @Sendable (A) -> B) -> AsyncStream<B?>
where A: Sendable {
    mapTAsyncStreamOptional(fn, stream)
}
