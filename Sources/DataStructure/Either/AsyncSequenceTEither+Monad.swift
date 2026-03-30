import Foundation

// AsyncSequenceTEither: outer = AsyncStream, inner = Either
// Type: AsyncStream<Either<L,A>>
// Haskell: ExceptT l AsyncStream

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTAsyncStreamEither<L, A, B>(
    _ stream: AsyncStream<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    AsyncStream<Either<L, B>> { continuation in
        let task = Task { @Sendable in
            for await either in stream {
                switch either {
                case let .left(l):
                    continuation.yield(.left(l))
                case let .right(a):
                    for await b in fn(a) {
                        continuation.yield(b)
                    }
                }
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTAsyncStreamEither<L, A, B>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> @Sendable (AsyncStream<Either<L, A>>) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    { @Sendable stream in flatMapTAsyncStreamEither(stream, fn) }
}
