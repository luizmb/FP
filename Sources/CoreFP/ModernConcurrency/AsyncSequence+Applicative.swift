// SPDX-License-Identifier: Apache-2.0
import Foundation

// The AsyncStream applicative is derived from its monad (`<*>` == `ap`), with Haskell stream
// semantics: bind is ordered concat, so `fs <*> xs` applies each function, in order, to the whole
// argument stream (cartesian, like the list applicative). It is *not* zip; use `zip` for pairing.
//
// The argument stream is single-pass but `ap` traverses it once per function, so it goes through
// ``AsyncStream/replayable(_:)``: drained once into a buffer (when the first left element arrives)
// and replayed for every left element. Nothing is dropped or reordered; an infinite argument never
// yields.

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream where Element: Sendable {
    /// Apply a stream of functions to a stream of values.
    /// (<*>) :: f (a -> b) -> f a -> f b
    /// fs <*> xs = fs >>= \f -> fmap f xs
    ///
    /// `[f, g] <*> [1, 2]` yields `f(1), f(2), g(1), g(2)`.
    static func apply<A: Sendable, B: Sendable>(
        _ functions: AsyncStream<@Sendable (A) -> B>,
        _ values: AsyncStream<A>
    ) -> AsyncStream<B> {
        let replay = AsyncStream<A>.replayable(values)
        return AsyncStream<B>.concatMap(functions) { f in AsyncStream<B>.mapStream(replay(), f) }
    }

    /// Lift a binary function to work with two streams.
    /// liftA2 :: (a -> b -> c) -> f a -> f b -> f c
    /// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
    ///
    /// `liftA2(+)([1, 2], [10, 20])` yields `11, 21, 12, 22`.
    static func liftA2<A: Sendable, B: Sendable, C: Sendable>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> @Sendable (AsyncStream<A>, AsyncStream<B>) -> AsyncStream<C> {
        { @Sendable streamA, streamB in
            let replay = AsyncStream<B>.replayable(streamB)
            return AsyncStream<C>.concatMap(streamA) { a in
                AsyncStream<C>.mapStream(replay()) { b in fn(a, b) }
            }
        }
    }

    /// seqRight :: AsyncStream<a> -> AsyncStream<b> -> AsyncStream<b>
    /// ma *> mb = ma >>= \_ -> mb
    ///
    /// For each left element, in order, yields the whole right stream: `[1, 2] *> [10, 20]` yields `10, 20, 10, 20`.
    /// Left runs first; the right stream is drained once and replayed.
    static func seqRight<A: Sendable, B: Sendable>(
        _ lhs: AsyncStream<A>,
        _ rhs: AsyncStream<B>
    ) -> AsyncStream<B> {
        liftA2 { @Sendable (_: A, b: B) in b }(lhs, rhs)
    }

    /// seqLeft :: AsyncStream<a> -> AsyncStream<b> -> AsyncStream<a>
    /// ma <* mb = ma >>= \a -> fmap (const a) mb
    ///
    /// Each left element is repeated once per right element: `[1, 2] <* [10, 20]` yields `1, 1, 2, 2`.
    /// Effects run in the same order as ``seqRight(_:_:)``: left first, then the right stream (drained once).
    static func seqLeft<A: Sendable, B: Sendable>(
        _ lhs: AsyncStream<A>,
        _ rhs: AsyncStream<B>
    ) -> AsyncStream<A> {
        liftA2 { @Sendable (a: A, _: B) in a }(lhs, rhs)
    }

    /// Zip two streams into a stream of tuples, pairing elements positionally.
    ///
    /// Not the applicative (``apply(_:_:)`` is cartesian): `zip([1, 2], ["a", "b"])` yields `(1, "a"), (2, "b")`
    /// and finishes as soon as either stream finishes.
    static func zip<A: Sendable, B: Sendable>(
        _ streamA: AsyncStream<A>,
        _ streamB: AsyncStream<B>
    ) -> AsyncStream<(A, B)> {
        AsyncStream<(A, B)> { continuation in
            let task = Task { @Sendable in
                var iterA = streamA.makeAsyncIterator()
                var iterB = streamB.makeAsyncIterator()

                while let a = await iterA.next(),
                      let b = await iterB.next() {
                    continuation.yield((a, b))
                }
                continuation.finish()
            }
            // swiftlint:disable:next closure_ignoring_args
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
