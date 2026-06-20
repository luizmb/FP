// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTResult: outer = AsyncStream, inner = Result
// Type: AsyncStream<Result<A,E>>

/// `mapTAsyncStreamResult`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func mapTAsyncStreamResult<A, B: Sendable, E: Error>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: AsyncStream<Result<A, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, E: Sendable {
    AsyncStream<Result<B, E>> { continuation in
        let task = Task { @Sendable in
            for await result in stream {
                continuation.yield(result.map(fn))
            }
            continuation.finish()
        }
        // swiftlint:disable:next closure_ignoring_args
        continuation.onTermination = { _ in task.cancel() }
    }
}

/// `fmapTAsyncStreamResult`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func fmapTAsyncStreamResult<A, B: Sendable, E: Error>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (AsyncStream<Result<A, E>>) -> AsyncStream<Result<B, E>> where A: Sendable, E: Sendable {
    { @Sendable stream in mapTAsyncStreamResult(fn, stream) }
}
