import CoreFPOperators
import DataStructure

// AsyncSequenceTEither: AsyncStream<Either<L,A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <L, A, B>(
    _ stream: AsyncStream<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    flatMapTAsyncStreamEither(stream, fn)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <L, A, B>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>,
    _ stream: AsyncStream<Either<L, A>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    flatMapTAsyncStreamEither(stream, fn)
}
