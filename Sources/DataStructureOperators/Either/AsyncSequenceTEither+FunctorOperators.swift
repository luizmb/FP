import DataStructure
import Core
import CoreOperators

// AsyncSequenceTEither: AsyncStream<Either<L,A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <L, A, B: Sendable>(_ fn: @escaping @Sendable (A) -> B, _ stream: AsyncStream<Either<L, A>>) -> AsyncStream<Either<L, B>>
where A: Sendable, L: Sendable {
    mapTAsyncStreamEither(fn, stream)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&> <L, A, B: Sendable>(_ stream: AsyncStream<Either<L, A>>, _ fn: @escaping @Sendable (A) -> B) -> AsyncStream<Either<L, B>>
where A: Sendable, L: Sendable {
    mapTAsyncStreamEither(fn, stream)
}
