// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTOptional: outer = AsyncStream, inner = Optional
// Type: AsyncStream<A?>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncStream {
    /// Maps the value inside every emitted Optional.
    /// mapT :: (a -> b) -> AsyncStream (optional a) -> AsyncStream (optional b)
    func mapT<Inner, B: Sendable>(_ fn: @escaping @Sendable (Inner) -> B) -> AsyncStream<B?>
    where Element == Inner?, Inner: Sendable {
        AsyncStream<B?> { continuation in
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
    static func fmapT<Inner, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (AsyncStream<Inner?>) -> AsyncStream<B?>
    where Element == Inner?, Inner: Sendable {
        { @Sendable stream in stream.mapT(fn) }
    }
}
