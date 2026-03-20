import Foundation

// AsyncSequenceTArray: outer = AsyncStream, inner = Array
// Type: AsyncStream<[A]>

/// flatMapT for AsyncStream<[A]>
/// For each emitted [A], apply fn to each element producing AsyncStream<[B]>,
/// zip all and concatenate
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTAsyncStreamArray<A, B>(
    _ stream: AsyncStream<[A]>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<[B]>
) -> AsyncStream<[B]> where A: Sendable, B: Sendable {
    AsyncStream<[B]> { continuation in
        Task { @Sendable in
            for await arr in stream {
                // For each emitted array, collect all fn results and concatenate
                var combined: [B] = []
                for a in arr {
                    for await bs in fn(a) {
                        combined.append(contentsOf: bs)
                    }
                }
                continuation.yield(combined)
            }
            continuation.finish()
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTAsyncStreamArray<A, B>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<[B]>
) -> @Sendable (AsyncStream<[A]>) -> AsyncStream<[B]> where A: Sendable, B: Sendable {
    { @Sendable stream in flatMapTAsyncStreamArray(stream, fn) }
}
