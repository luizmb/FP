import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream where Element: Sendable {
    /// Apply a stream of functions to a stream of values
    /// For AsyncStream we provide basic applicative support through zipping
    /// (<*>) :: f (a -> b) -> f a -> f b
    static func apply<A: Sendable, B: Sendable>(
        _ functions: AsyncStream<@Sendable (A) -> B>,
        _ values: AsyncStream<A>
    ) -> AsyncStream<B> {
        AsyncStream<B> { continuation in
            Task { @Sendable in
                var funcIterator = functions.makeAsyncIterator()
                var valueIterator = values.makeAsyncIterator()

                while let fn = await funcIterator.next(),
                      let value = await valueIterator.next() {
                    continuation.yield(fn(value))
                }
                continuation.finish()
            }
        }
    }

    /// Lift a binary function to work with two streams
    /// liftA2 :: (a -> b -> c) -> f a -> f b -> f c
    static func liftA2<A: Sendable, B: Sendable, C: Sendable>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> @Sendable (AsyncStream<A>, AsyncStream<B>) -> AsyncStream<C> {
        { @Sendable (streamA, streamB) in
            AsyncStream<C> { continuation in
                Task { @Sendable in
                    var iterA = streamA.makeAsyncIterator()
                    var iterB = streamB.makeAsyncIterator()

                    while let a = await iterA.next(),
                          let b = await iterB.next() {
                        continuation.yield(fn(a, b))
                    }
                    continuation.finish()
                }
            }
        }
    }

    /// seqRight :: AsyncStream<a> -> AsyncStream<b> -> AsyncStream<b>
    /// Run both concurrently, discard left values, yield right values
    static func seqRight<A: Sendable, B: Sendable>(
        _ lhs: AsyncStream<A>,
        _ rhs: AsyncStream<B>
    ) -> AsyncStream<B> {
        AsyncStream<B> { continuation in
            Task { @Sendable in
                var lhsIter = lhs.makeAsyncIterator()
                var rhsIter = rhs.makeAsyncIterator()

                while let _ = await lhsIter.next(),
                      let b = await rhsIter.next() {
                    continuation.yield(b)
                }
                continuation.finish()
            }
        }
    }

    /// Zip two streams into a stream of tuples
    static func zip<A: Sendable, B: Sendable>(
        _ streamA: AsyncStream<A>,
        _ streamB: AsyncStream<B>
    ) -> AsyncStream<(A, B)> {
        AsyncStream<(A, B)> { continuation in
            Task { @Sendable in
                var iterA = streamA.makeAsyncIterator()
                var iterB = streamB.makeAsyncIterator()

                while let a = await iterA.next(),
                      let b = await iterB.next() {
                    continuation.yield((a, b))
                }
                continuation.finish()
            }
        }
    }
}
