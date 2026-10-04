// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTEither: outer = AsyncStream, inner = Either
// Type: AsyncStream<Either<L, A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    /// Maps the value inside every emitted Either.
    /// mapT :: (a -> b) -> AsyncStream (either a) -> AsyncStream (either b)
    func mapT<L, Inner, B: Sendable>(_ fn: @escaping @Sendable (Inner) -> B) -> AsyncStream<Either<L, B>>
    where Element == Either<L, Inner>, Inner: Sendable, L: Sendable {
        AsyncStream<Either<L, B>> { continuation in
            let task = Task { @Sendable in
                for await element in self {
                    continuation.yield(element.mapRight(fn))
                }
                continuation.finish()
            }
            // swiftlint:disable:next closure_ignoring_args
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<L, Inner, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (AsyncStream<Either<L, Inner>>) -> AsyncStream<Either<L, B>>
    where Element == Either<L, Inner>, Inner: Sendable, L: Sendable {
        { @Sendable stream in stream.mapT(fn) }
    }
}
