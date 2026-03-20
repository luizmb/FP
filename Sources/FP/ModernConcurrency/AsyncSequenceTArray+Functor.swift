import Foundation

// AsyncSequenceTArray: outer = AsyncStream, inner = Array
// Type: AsyncStream<[A]>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func mapTAsyncStreamArray<A, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: AsyncStream<[A]>
) -> AsyncStream<[B]> where A: Sendable {
    AsyncStream<[B]> { continuation in
        Task { @Sendable in
            for await arr in stream {
                continuation.yield(arr.map(fn))
            }
            continuation.finish()
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func fmapTAsyncStreamArray<A, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (AsyncStream<[A]>) -> AsyncStream<[B]> where A: Sendable {
    { @Sendable stream in mapTAsyncStreamArray(fn, stream) }
}
