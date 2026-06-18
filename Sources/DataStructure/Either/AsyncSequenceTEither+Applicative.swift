// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTEither: outer = AsyncStream, inner = Either
// Type: AsyncStream<Either<L,A>>

/// `liftA2AsyncStreamEither`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2AsyncStreamEither<L, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (AsyncStream<Either<L, A>>, AsyncStream<Either<L, B>>) -> AsyncStream<Either<L, C>>
where A: Sendable, B: Sendable, C: Sendable, L: Sendable {
    { @Sendable streamA, streamB in
        AsyncStream<Either<L, C>> { continuation in
            let task = Task { @Sendable in
                var iterA = streamA.makeAsyncIterator()
                var iterB = streamB.makeAsyncIterator()
                while let a = await iterA.next(), let b = await iterB.next() {
                    continuation.yield(Either.liftA2(fn)(a, b))
                }
                continuation.finish()
            }
            // swiftlint:disable:next closure_ignoring_args
            // swiftlint:disable:next closure_ignoring_args
        continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// `seqRightAsyncStreamEither`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightAsyncStreamEither<L, A, B>(
    _ lhs: AsyncStream<Either<L, A>>,
    _ rhs: AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    AsyncStream<Either<L, B>> { continuation in
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

/// `seqLeftAsyncStreamEither`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftAsyncStreamEither<L, A, B>(
    _ lhs: AsyncStream<Either<L, A>>,
    _ rhs: AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, A>> where A: Sendable, B: Sendable, L: Sendable {
    AsyncStream<Either<L, A>> { continuation in
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
