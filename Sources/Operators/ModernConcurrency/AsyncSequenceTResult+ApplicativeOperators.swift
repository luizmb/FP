import FP

// AsyncSequenceTResult: AsyncStream<Result<A,E>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <A, B, E: Error>(
    _ lhs: AsyncStream<Result<A, E>>,
    _ rhs: AsyncStream<Result<B, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    seqRightAsyncStreamResult(lhs, rhs)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <A, B, E: Error>(
    _ lhs: AsyncStream<Result<A, E>>,
    _ rhs: AsyncStream<Result<B, E>>
) -> AsyncStream<Result<A, E>> where A: Sendable, B: Sendable, E: Sendable {
    seqLeftAsyncStreamResult(lhs, rhs)
}
