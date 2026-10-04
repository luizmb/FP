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

// (>=>) :: (a -> AsyncStream<b?>) -> (b -> AsyncStream<c?>) -> a -> AsyncStream<c?>
/// `>=>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >=> <A, B, C>(
    _ fn1: @escaping @Sendable (A) -> AsyncStream<B?>,
    _ fn2: @escaping @Sendable (B) -> AsyncStream<C?>
) -> @Sendable (A) -> AsyncStream<C?> where B: Sendable, C: Sendable {
    kleisliTAsyncStreamOptional(fn1, fn2)
}

// (<=<) :: (b -> AsyncStream<c?>) -> (a -> AsyncStream<b?>) -> a -> AsyncStream<c?>
/// `<=<` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <=< <A, B, C>(
    _ fn2: @escaping @Sendable (B) -> AsyncStream<C?>,
    _ fn1: @escaping @Sendable (A) -> AsyncStream<B?>
) -> @Sendable (A) -> AsyncStream<C?> where B: Sendable, C: Sendable {
    fn1 >=> fn2
}
