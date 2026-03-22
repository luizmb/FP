import Foundation

// AsyncSequenceTOptional: outer = AsyncStream, inner = Optional
// Type: AsyncStream<A?>

/// mapT for AsyncStream<A?> — maps over the inner Optional
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func mapTAsyncStreamOptional<A, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: AsyncStream<A?>
) -> AsyncStream<B?> where A: Sendable {
    AsyncStream<B?> { continuation in
        Task { @Sendable in
            for await optA in stream {
                continuation.yield(optA.map(fn))
            }
            continuation.finish()
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func fmapTAsyncStreamOptional<A, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (AsyncStream<A?>) -> AsyncStream<B?> where A: Sendable {
    { @Sendable stream in mapTAsyncStreamOptional(fn, stream) }
}
