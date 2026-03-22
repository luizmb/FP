import Foundation

// AsyncSequenceTResult: outer = AsyncStream, inner = Result
// Type: AsyncStream<Result<A,E>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2AsyncStreamResult<A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (AsyncStream<Result<A, E>>, AsyncStream<Result<B, E>>) -> AsyncStream<Result<C, E>>
where A: Sendable, B: Sendable, C: Sendable, E: Sendable {
    { @Sendable streamA, streamB in
        AsyncStream<Result<C, E>> { continuation in
            Task { @Sendable in
                var iterA = streamA.makeAsyncIterator()
                var iterB = streamB.makeAsyncIterator()
                while let a = await iterA.next(), let b = await iterB.next() {
                    continuation.yield(Result.liftA2(fn)(a, b))
                }
                continuation.finish()
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightAsyncStreamResult<A, B, E: Error>(
    _ lhs: AsyncStream<Result<A, E>>,
    _ rhs: AsyncStream<Result<B, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    AsyncStream<Result<B, E>> { continuation in
        Task { @Sendable in
            var lhsIter = lhs.makeAsyncIterator()
            var rhsIter = rhs.makeAsyncIterator()
            while let a = await lhsIter.next(), let b = await rhsIter.next() {
                continuation.yield(a.seqRight(b))
            }
            continuation.finish()
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftAsyncStreamResult<A, B, E: Error>(
    _ lhs: AsyncStream<Result<A, E>>,
    _ rhs: AsyncStream<Result<B, E>>
) -> AsyncStream<Result<A, E>> where A: Sendable, B: Sendable, E: Sendable {
    AsyncStream<Result<A, E>> { continuation in
        Task { @Sendable in
            var lhsIter = lhs.makeAsyncIterator()
            var rhsIter = rhs.makeAsyncIterator()
            while let a = await lhsIter.next(), let b = await rhsIter.next() {
                continuation.yield(a.seqLeft(b))
            }
            continuation.finish()
        }
    }
}
