// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// AsyncStreamTWriter: AsyncStream<Writer<W, A>>

/// (<*>) :: AsyncStream<Writer<w, (a -> b)>> -> AsyncStream<Writer<w, a>> -> AsyncStream<Writer<w, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <*> <W: Monoid, A, B>(
    _ fns: AsyncStream<Writer<W, @Sendable (A) -> B>>,
    _ values: AsyncStream<Writer<W, A>>
) -> AsyncStream<Writer<W, B>> where A: Sendable, B: Sendable {
    applyAsyncStreamWriter(fns, values)
}

/// (*>) :: AsyncStream<Writer<w, a>> -> AsyncStream<Writer<w, b>> -> AsyncStream<Writer<w, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <W: Monoid, A, B>(
    _ lhs: AsyncStream<Writer<W, A>>,
    _ rhs: AsyncStream<Writer<W, B>>
) -> AsyncStream<Writer<W, B>> where A: Sendable, B: Sendable {
    seqRightAsyncStreamWriter(lhs, rhs)
}

/// (<*) :: AsyncStream<Writer<w, a>> -> AsyncStream<Writer<w, b>> -> AsyncStream<Writer<w, a>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <W: Monoid, A, B>(
    _ lhs: AsyncStream<Writer<W, A>>,
    _ rhs: AsyncStream<Writer<W, B>>
) -> AsyncStream<Writer<W, A>> where A: Sendable, B: Sendable {
    seqLeftAsyncStreamWriter(lhs, rhs)
}
