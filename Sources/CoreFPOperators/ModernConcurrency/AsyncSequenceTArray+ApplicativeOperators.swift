// SPDX-License-Identifier: Apache-2.0
import CoreFP

// AsyncSequenceTArray: AsyncStream<[A]>

/// `*>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <A, B>(_ lhs: AsyncStream<[A]>, _ rhs: AsyncStream<[B]>) -> AsyncStream<[B]>
where A: Sendable, B: Sendable {
    seqRightAsyncStreamArray(lhs, rhs)
}

/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <A, B>(_ lhs: AsyncStream<[A]>, _ rhs: AsyncStream<[B]>) -> AsyncStream<[A]>
where A: Sendable, B: Sendable {
    seqLeftAsyncStreamArray(lhs, rhs)
}
