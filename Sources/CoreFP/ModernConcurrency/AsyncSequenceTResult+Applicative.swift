// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTResult: outer = AsyncStream, inner = Result
// Type: AsyncStream<Result<A,E>>
// Haskell: ExceptT e AsyncStream
//
// The applicative is derived from the monad (`<*>` = `ap`): built from `flatMapTAsyncStreamResult`
// (ordered concat) and `mapT`. A `.failure` on the left is emitted once and never
// touches the right side; every `.success` on the left runs over the whole right stream, in order.
// The right stream is single-pass, so it is drained once and replayed (see `AsyncStream.replayable`).

/// apply for AsyncStream<Result<A,E>>
/// mf <*> ma = mf >>= \f -> fmap f ma
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func applyAsyncStreamResult<A, B, E: Error>(
    _ fns: AsyncStream<Result<@Sendable (A) -> B, E>>,
    _ values: AsyncStream<Result<A, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    let replay = AsyncStream<Result<A, E>>.replayable(values)
    return flatMapTAsyncStreamResult(fns) { f in replay().mapT(f) }
}

/// liftA2 for AsyncStream<Result<A,E>>
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2AsyncStreamResult<A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (AsyncStream<Result<A, E>>, AsyncStream<Result<B, E>>) -> AsyncStream<Result<C, E>>
where A: Sendable, B: Sendable, C: Sendable, E: Sendable {
    { @Sendable streamA, streamB in
        let replay = AsyncStream<Result<B, E>>.replayable(streamB)
        return flatMapTAsyncStreamResult(streamA) { a in
            replay().mapT { b in fn(a, b) }
        }
    }
}

/// seqRight for AsyncStream<Result<A,E>>
/// ma *> mb = ma >>= \_ -> mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightAsyncStreamResult<A, B, E: Error>(
    _ lhs: AsyncStream<Result<A, E>>,
    _ rhs: AsyncStream<Result<B, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    liftA2AsyncStreamResult { @Sendable (_: A, b: B) in b }(lhs, rhs)
}

/// seqLeft for AsyncStream<Result<A,E>>
/// ma <* mb = ma >>= \a -> fmap (const a) mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftAsyncStreamResult<A, B, E: Error>(
    _ lhs: AsyncStream<Result<A, E>>,
    _ rhs: AsyncStream<Result<B, E>>
) -> AsyncStream<Result<A, E>> where A: Sendable, B: Sendable, E: Sendable {
    liftA2AsyncStreamResult { @Sendable (a: A, _: B) in a }(lhs, rhs)
}
