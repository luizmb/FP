// SPDX-License-Identifier: Apache-2.0
import CoreFP

// AsyncSequenceTResult: AsyncStream<Result<A,E>>

/// `<*>` overload: `ap` derived from the bind (ordered concat), not zip.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <*> <A, B, E: Error>(
    _ fns: AsyncStream<Result<@Sendable (A) -> B, E>>,
    _ values: AsyncStream<Result<A, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    applyAsyncStreamResult(fns, values)
}

/// `*>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <A, B, E: Error>(
    _ lhs: AsyncStream<Result<A, E>>,
    _ rhs: AsyncStream<Result<B, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    seqRightAsyncStreamResult(lhs, rhs)
}

/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <A, B, E: Error>(
    _ lhs: AsyncStream<Result<A, E>>,
    _ rhs: AsyncStream<Result<B, E>>
) -> AsyncStream<Result<A, E>> where A: Sendable, B: Sendable, E: Sendable {
    seqLeftAsyncStreamResult(lhs, rhs)
}
