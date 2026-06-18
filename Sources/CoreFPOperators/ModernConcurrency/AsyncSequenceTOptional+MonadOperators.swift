// SPDX-License-Identifier: Apache-2.0
import CoreFP

// AsyncSequenceTOptional: AsyncStream<A?>

// (>>-) :: AsyncStream<a?> -> @Sendable (a -> AsyncStream<b?>) -> AsyncStream<b?>
/// `>>-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <A, B>(_ stream: AsyncStream<A?>, _ fn: @escaping @Sendable (A) -> AsyncStream<B?>) -> AsyncStream<B?>
where A: Sendable, B: Sendable {
    flatMapTAsyncStreamOptional(stream, fn)
}

// (-<<) :: @Sendable (a -> AsyncStream<b?>) -> AsyncStream<a?> -> AsyncStream<b?>
/// `-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <A, B>(_ fn: @escaping @Sendable (A) -> AsyncStream<B?>, _ stream: AsyncStream<A?>) -> AsyncStream<B?>
where A: Sendable, B: Sendable {
    flatMapTAsyncStreamOptional(stream, fn)
}
