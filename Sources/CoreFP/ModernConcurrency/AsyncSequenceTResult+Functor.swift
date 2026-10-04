// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTResult: outer = AsyncStream, inner = Result
// Type: AsyncStream<Result<A, E>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    /// Maps the value inside every emitted Result.
    /// mapT :: (a -> b) -> AsyncStream (result a) -> AsyncStream (result b)
    func mapT<Inner, B: Sendable, E: Error>(_ fn: @escaping @Sendable (Inner) -> B) -> AsyncStream<Result<B, E>>
    where Element == Result<Inner, E>, Inner: Sendable, E: Sendable {
        AsyncStream<Result<B, E>> { continuation in
            let task = Task { @Sendable in
                for await element in self {
                    continuation.yield(element.map(fn))
                }
                continuation.finish()
            }
            // swiftlint:disable:next closure_ignoring_args
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, B: Sendable, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (AsyncStream<Result<Inner, E>>) -> AsyncStream<Result<B, E>>
    where Element == Result<Inner, E>, Inner: Sendable, E: Sendable {
        { @Sendable stream in stream.mapT(fn) }
    }
}
