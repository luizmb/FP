import CoreFP

// AsyncSequenceTResult: AsyncStream<Result<A,E>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <A, B: Sendable, E: Error>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: AsyncStream<Result<A, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, E: Sendable {
    mapTAsyncStreamResult(fn, stream)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&> <A, B: Sendable, E: Error>(
    _ stream: AsyncStream<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> B
) -> AsyncStream<Result<B, E>> where A: Sendable, E: Sendable {
    mapTAsyncStreamResult(fn, stream)
}
