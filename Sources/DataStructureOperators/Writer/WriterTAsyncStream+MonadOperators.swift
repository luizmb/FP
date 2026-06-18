// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: Writer<w, AsyncStream<a>> -> (a async throws -> Writer<w, b: AsyncSequence>) -> Writer<w, AsyncThrowingFlatMapSequence<...>>
/// `>>-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <W: Monoid, A: Sendable, B: AsyncSequence>(
    _ writer: Writer<W, AsyncStream<A>>,
    _ fn: @escaping @Sendable (A) async throws -> Writer<W, B>
) -> Writer<W, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>, B>, B>> {
    writer.flatMapT(fn)
}

// (-<<) :: (a async throws -> Writer<w, b: AsyncSequence>) -> Writer<w, AsyncStream<a>> -> Writer<w, AsyncThrowingFlatMapSequence<...>>
/// `-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <W: Monoid, A: Sendable, B: AsyncSequence>(
    _ fn: @escaping @Sendable (A) async throws -> Writer<W, B>,
    _ writer: Writer<W, AsyncStream<A>>
) -> Writer<W, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>, B>, B>> {
    writer >>- fn
}
