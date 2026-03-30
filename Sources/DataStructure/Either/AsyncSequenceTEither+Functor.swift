import Foundation

// AsyncSequenceTEither: outer = AsyncStream, inner = Either
// Type: AsyncStream<Either<L,A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func mapTAsyncStreamEither<L, A, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: AsyncStream<Either<L, A>>
) -> AsyncStream<Either<L, B>> where A: Sendable, L: Sendable {
    AsyncStream<Either<L, B>> { continuation in
        let task = Task { @Sendable in
            for await either in stream {
                continuation.yield(either.mapRight(fn))
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func fmapTAsyncStreamEither<L, A, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (AsyncStream<Either<L, A>>) -> AsyncStream<Either<L, B>> where A: Sendable, L: Sendable {
    { @Sendable stream in mapTAsyncStreamEither(fn, stream) }
}
