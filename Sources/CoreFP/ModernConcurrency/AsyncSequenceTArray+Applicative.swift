// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTArray: outer = AsyncStream, inner = Array
// Type: AsyncStream<[A]>
//
// The applicative is the composition of AsyncStream's applicative (`ap`: ordered concat, the
// argument stream buffered once and replayed) with Array's (cartesian). It is not zip.

/// `liftA2AsyncStreamArray`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func liftA2AsyncStreamArray<A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (AsyncStream<[A]>, AsyncStream<[B]>) -> AsyncStream<[C]>
where A: Sendable, B: Sendable, C: Sendable {
    AsyncStream<[C]>.liftA2 { @Sendable (a: [A], b: [B]) in Array.liftA2(fn)(a, b) }
}

/// `seqRightAsyncStreamArray`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func seqRightAsyncStreamArray<A, B>(
    _ lhs: AsyncStream<[A]>,
    _ rhs: AsyncStream<[B]>
) -> AsyncStream<[B]> where A: Sendable, B: Sendable {
    AsyncStream<[B]>.liftA2 { @Sendable (a: [A], b: [B]) in a.seqRight(b) }(lhs, rhs)
}

/// `seqLeftAsyncStreamArray`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func seqLeftAsyncStreamArray<A, B>(
    _ lhs: AsyncStream<[A]>,
    _ rhs: AsyncStream<[B]>
) -> AsyncStream<[A]> where A: Sendable, B: Sendable {
    AsyncStream<[A]>.liftA2 { @Sendable (a: [A], b: [B]) in a.seqLeft(b) }(lhs, rhs)
}
