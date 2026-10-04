// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// AsyncSequenceTEither: outer = AsyncStream, inner = Either
// Type: AsyncStream<Either<L,A>>
// Haskell: ExceptT l AsyncStream
//
// The applicative is derived from the monad (`<*>` = `ap`): built from `flatMapTAsyncStreamEither`
// (ordered concat) and `mapT`. A `.left` on the left is emitted once and never
// touches the right side; every `.right` on the left runs over the whole right stream, in order.
// The right stream is single-pass, so it is drained once and replayed (see `AsyncStream.replayable`).

/// apply for AsyncStream<Either<L,A>>
/// mf <*> ma = mf >>= \f -> fmap f ma
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func applyAsyncStreamEither<L, A, B>(
    _ fns: AsyncStream<Either<L, @Sendable (A) -> B>>,
    _ values: AsyncStream<Either<L, A>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    let replay = AsyncStream<Either<L, A>>.replayable(values)
    return flatMapTAsyncStreamEither(fns) { f in replay().mapT(f) }
}

/// liftA2 for AsyncStream<Either<L,A>>
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2AsyncStreamEither<L, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (AsyncStream<Either<L, A>>, AsyncStream<Either<L, B>>) -> AsyncStream<Either<L, C>>
where A: Sendable, B: Sendable, C: Sendable, L: Sendable {
    { @Sendable streamA, streamB in
        let replay = AsyncStream<Either<L, B>>.replayable(streamB)
        return flatMapTAsyncStreamEither(streamA) { a in
            replay().mapT { b in fn(a, b) }
        }
    }
}

/// seqRight for AsyncStream<Either<L,A>>
/// ma *> mb = ma >>= \_ -> mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightAsyncStreamEither<L, A, B>(
    _ lhs: AsyncStream<Either<L, A>>,
    _ rhs: AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    liftA2AsyncStreamEither { @Sendable (_: A, b: B) in b }(lhs, rhs)
}

/// seqLeft for AsyncStream<Either<L,A>>
/// ma <* mb = ma >>= \a -> fmap (const a) mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftAsyncStreamEither<L, A, B>(
    _ lhs: AsyncStream<Either<L, A>>,
    _ rhs: AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, A>> where A: Sendable, B: Sendable, L: Sendable {
    liftA2AsyncStreamEither { @Sendable (a: A, _: B) in a }(lhs, rhs)
}
