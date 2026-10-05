// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// AsyncStreamTWriter: outer = AsyncStream, inner = Writer
// Type: AsyncStream<Writer<W, A>>  (Haskell: WriterT w AsyncStream a)
//
// The applicative is derived from the monad (`<*>` = `ap`): built from `flatMapT` (ordered concat,
// logs `w1 <> w2`) and `pure`. Every left element runs over the whole right stream, in order, and
// each result carries the left log followed by the right log. The right stream is single-pass, so
// it is drained once and replayed (see `AsyncStream.replayable`).

/// apply for AsyncStream<Writer<W, A>>
/// mf <*> ma = mf >>= \f -> ma >>= \a -> pure (f a)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func applyAsyncStreamWriter<W: Monoid, A, B>(
    _ fns: AsyncStream<Writer<W, @Sendable (A) -> B>>,
    _ values: AsyncStream<Writer<W, A>>
) -> AsyncStream<Writer<W, B>> where A: Sendable, B: Sendable {
    liftA2AsyncStreamWriter { @Sendable (f: @Sendable (A) -> B, a: A) in f(a) }(fns, values)
}

/// liftA2 for AsyncStream<Writer<W, A>>
/// liftA2 f ma mb = ma >>= \a -> mb >>= \b -> pure (f a b)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func liftA2AsyncStreamWriter<W: Monoid, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (AsyncStream<Writer<W, A>>, AsyncStream<Writer<W, B>>) -> AsyncStream<Writer<W, C>>
where A: Sendable, B: Sendable, C: Sendable {
    { @Sendable streamA, streamB in
        let replay = AsyncStream<Writer<W, B>>.replayable(streamB)
        return streamA.flatMapT { a in
            replay().flatMapT { b in pureAsyncStreamWriter(fn(a, b)) }
        }
    }
}

/// seqRight for AsyncStream<Writer<W, A>>
/// ma *> mb = ma >>= \_ -> mb
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func seqRightAsyncStreamWriter<W: Monoid, A, B>(
    _ lhs: AsyncStream<Writer<W, A>>,
    _ rhs: AsyncStream<Writer<W, B>>
) -> AsyncStream<Writer<W, B>> where A: Sendable, B: Sendable {
    liftA2AsyncStreamWriter { @Sendable (_: A, b: B) in b }(lhs, rhs)
}

/// seqLeft for AsyncStream<Writer<W, A>>
/// ma <* mb = ma >>= \a -> mb >>= \_ -> pure a
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func seqLeftAsyncStreamWriter<W: Monoid, A, B>(
    _ lhs: AsyncStream<Writer<W, A>>,
    _ rhs: AsyncStream<Writer<W, B>>
) -> AsyncStream<Writer<W, A>> where A: Sendable, B: Sendable {
    liftA2AsyncStreamWriter { @Sendable (a: A, _: B) in a }(lhs, rhs)
}

/// `return` of the stack: one element with an empty log.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private func pureAsyncStreamWriter<W: Monoid, A: Sendable>(_ value: A) -> AsyncStream<Writer<W, A>> {
    AsyncStream { continuation in
        continuation.yield(Writer.pure(value))
        continuation.finish()
    }
}
