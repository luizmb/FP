// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// AsyncStreamTWriter: AsyncStream<Writer<W, A>>

// (>>-) :: AsyncStream<Writer<w, a>> -> (a -> AsyncStream<Writer<w, b>>) -> AsyncStream<Writer<w, b>>
/// `>>-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <W: Monoid, A, B>(
    _ stream: AsyncStream<Writer<W, A>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Writer<W, B>>
) -> AsyncStream<Writer<W, B>> where A: Sendable, B: Sendable {
    stream.flatMapT(fn)
}

// (-<<) :: (a -> AsyncStream<Writer<w, b>>) -> AsyncStream<Writer<w, a>> -> AsyncStream<Writer<w, b>>
/// `-<<` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Writer<W, B>>,
    _ stream: AsyncStream<Writer<W, A>>
) -> AsyncStream<Writer<W, B>> where A: Sendable, B: Sendable {
    stream >>- fn
}

// (>=>) :: (a -> AsyncStream<Writer<w, b>>) -> (b -> AsyncStream<Writer<w, c>>) -> a -> AsyncStream<Writer<w, c>>
/// `>=>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >=> <W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Writer<W, C>>
) -> @Sendable (A) -> AsyncStream<Writer<W, C>> where B: Sendable, C: Sendable {
    kleisliT(fn1, fn2)
}

// (<=<) :: (b -> AsyncStream<Writer<w, c>>) -> (a -> AsyncStream<Writer<w, b>>) -> a -> AsyncStream<Writer<w, c>>
/// `<=<` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <=< <W: Monoid, A, B, C>(
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Writer<W, C>>,
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Writer<W, B>>
) -> @Sendable (A) -> AsyncStream<Writer<W, C>> where B: Sendable, C: Sendable {
    fn1 >=> fn2
}
