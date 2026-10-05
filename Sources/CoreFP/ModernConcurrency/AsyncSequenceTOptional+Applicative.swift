// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTOptional: outer = AsyncStream, inner = Optional
// Type: AsyncStream<A?>
// Haskell: MaybeT AsyncStream
//
// The applicative is derived from the monad (`<*>` = `ap`): built from `flatMapTAsyncStreamOptional`
// (ordered concat) and `mapT`. A `nil` on the left yields a single `nil` and never
// touches the right side; every `.some` on the left runs over the whole right stream, in order.
// The right stream is single-pass, so it is drained once and replayed (see `AsyncStream.replayable`).

/// apply for AsyncStream<A?>
/// mf <*> ma = mf >>= \f -> fmap f ma
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func applyAsyncStreamOptional<A, B>(
    _ fns: AsyncStream<(@Sendable (A) -> B)?>,
    _ values: AsyncStream<A?>
) -> AsyncStream<B?> where A: Sendable, B: Sendable {
    let replay = AsyncStream<A?>.replayable(values)
    return flatMapTAsyncStreamOptional(fns) { f in replay().mapT(f) }
}

/// liftA2 for AsyncStream<A?>
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func liftA2AsyncStreamOptional<A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (AsyncStream<A?>, AsyncStream<B?>) -> AsyncStream<C?>
where A: Sendable, B: Sendable, C: Sendable {
    { @Sendable streamA, streamB in
        let replay = AsyncStream<B?>.replayable(streamB)
        return flatMapTAsyncStreamOptional(streamA) { a in
            replay().mapT { b in fn(a, b) }
        }
    }
}

/// seqRight for AsyncStream<A?>
/// ma *> mb = ma >>= \_ -> mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func seqRightAsyncStreamOptional<A, B>(
    _ lhs: AsyncStream<A?>,
    _ rhs: AsyncStream<B?>
) -> AsyncStream<B?> where A: Sendable, B: Sendable {
    liftA2AsyncStreamOptional { @Sendable (_: A, b: B) in b }(lhs, rhs)
}

/// seqLeft for AsyncStream<A?>
/// ma <* mb = ma >>= \a -> fmap (const a) mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func seqLeftAsyncStreamOptional<A, B>(
    _ lhs: AsyncStream<A?>,
    _ rhs: AsyncStream<B?>
) -> AsyncStream<A?> where A: Sendable, B: Sendable {
    liftA2AsyncStreamOptional { @Sendable (a: A, _: B) in a }(lhs, rhs)
}
