// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTEither: outer = AsyncStream, inner = Either
// Type: AsyncStream<Either<L,A>>
// Haskell: ExceptT l AsyncStream

/// `flatMapTAsyncStreamEither`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTAsyncStreamEither<L, A, B>(
    _ stream: AsyncStream<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    AsyncStream<Either<L, B>> { continuation in
        let task = Task { @Sendable in
            for await either in stream {
                switch either {
                case let .left(l):
                    continuation.yield(.left(l))

                case let .right(a):
                    for await b in fn(a) {
                        continuation.yield(b)
                    }
                }
            }
            continuation.finish()
        }
        // swiftlint:disable:next closure_ignoring_args
        continuation.onTermination = { _ in task.cancel() }
    }
}

/// `bindTAsyncStreamEither`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTAsyncStreamEither<L, A, B>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> @Sendable (AsyncStream<Either<L, A>>) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    { @Sendable stream in flatMapTAsyncStreamEither(stream, fn) }
}

/// Kleisli composition for AsyncStream<Either<L,A>> (left-to-right)
/// (>=>) :: (a -> AsyncStream<Either<l,b>>) -> (b -> AsyncStream<Either<l,c>>) -> a -> AsyncStream<Either<l,c>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func kleisliTAsyncStreamEither<L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>,
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Either<L, C>>
) -> @Sendable (A) -> AsyncStream<Either<L, C>> where B: Sendable, C: Sendable, L: Sendable {
    { a in flatMapTAsyncStreamEither(fn1(a), fn2) }
}
