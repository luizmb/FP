// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTOptional: outer = AsyncStream, inner = Optional
// Type: AsyncStream<A?>
// Haskell: MaybeT AsyncStream

/// flatMapT for AsyncStream<A?>
/// .none → emit .none
/// .some(a) → flatten fn(a) elements
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTAsyncStreamOptional<A, B>(
    _ stream: AsyncStream<A?>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<B?>
) -> AsyncStream<B?> where A: Sendable, B: Sendable {
    AsyncStream<B?> { continuation in
        let task = Task { @Sendable in
            for await optA in stream {
                if let a = optA {
                    for await b in fn(a) {
                        continuation.yield(b)
                    }
                } else {
                    continuation.yield(.none)
                }
            }
            continuation.finish()
        }
        // swiftlint:disable:next closure_ignoring_args
        continuation.onTermination = { _ in task.cancel() }
    }
}

/// `bindTAsyncStreamOptional`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTAsyncStreamOptional<A, B>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<B?>
) -> @Sendable (AsyncStream<A?>) -> AsyncStream<B?> where A: Sendable, B: Sendable {
    { @Sendable stream in flatMapTAsyncStreamOptional(stream, fn) }
}
