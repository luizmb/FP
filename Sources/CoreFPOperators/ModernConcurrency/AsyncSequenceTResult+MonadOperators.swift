import CoreFP

// AsyncSequenceTResult: AsyncStream<Result<A,E>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <A, B, E: Error>(
    _ stream: AsyncStream<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    flatMapTAsyncStreamResult(stream, fn)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>,
    _ stream: AsyncStream<Result<A, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    flatMapTAsyncStreamResult(stream, fn)
}
