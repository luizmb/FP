// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTOptional: outer = AsyncStream, inner = Optional
// Type: AsyncStream<A?>

/// liftA2 for AsyncStream<A?> — zips two streams, applying Optional liftA2 to each pair
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2AsyncStreamOptional<A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (AsyncStream<A?>, AsyncStream<B?>) -> AsyncStream<C?>
where A: Sendable, B: Sendable, C: Sendable {
    { @Sendable streamA, streamB in
        AsyncStream<C?> { continuation in
            let task = Task { @Sendable in
                var iterA = streamA.makeAsyncIterator()
                var iterB = streamB.makeAsyncIterator()
                while let a = await iterA.next(), let b = await iterB.next() {
                    continuation.yield(Optional.liftA2(fn)(a, b))
                }
                continuation.finish()
            }
            // swiftlint:disable:next closure_ignoring_args
            // swiftlint:disable:next closure_ignoring_args
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// seqRight for AsyncStream<A?>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightAsyncStreamOptional<A, B>(
    _ lhs: AsyncStream<A?>,
    _ rhs: AsyncStream<B?>
) -> AsyncStream<B?> where A: Sendable, B: Sendable {
    AsyncStream<B?> { continuation in
        let task = Task { @Sendable in
            var lhsIter = lhs.makeAsyncIterator()
            var rhsIter = rhs.makeAsyncIterator()
            while let a = await lhsIter.next(), let b = await rhsIter.next() {
                continuation.yield(a.seqRight(b))
            }
            continuation.finish()
        }
        // swiftlint:disable:next closure_ignoring_args
        continuation.onTermination = { _ in task.cancel() }
    }
}

/// seqLeft for AsyncStream<A?>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftAsyncStreamOptional<A, B>(
    _ lhs: AsyncStream<A?>,
    _ rhs: AsyncStream<B?>
) -> AsyncStream<A?> where A: Sendable, B: Sendable {
    AsyncStream<A?> { continuation in
        let task = Task { @Sendable in
            var lhsIter = lhs.makeAsyncIterator()
            var rhsIter = rhs.makeAsyncIterator()
            while let a = await lhsIter.next(), let b = await rhsIter.next() {
                continuation.yield(a.seqLeft(b))
            }
            continuation.finish()
        }
        // swiftlint:disable:next closure_ignoring_args
        continuation.onTermination = { _ in task.cancel() }
    }
}
