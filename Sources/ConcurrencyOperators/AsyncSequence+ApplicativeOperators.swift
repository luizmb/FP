import ConcurrencyFP
import Foundation
import FP
import Operators

// (<*>) :: f (a -> b) -> f a -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <*> <A: Sendable, B: Sendable>(
    _ functions: AsyncStream<@Sendable (A) -> B>,
    _ values: AsyncStream<A>
) -> AsyncStream<B> {
    AsyncStream<B>.apply(functions, values)
}

// (*>) :: f a -> f b -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <A: Sendable, B: Sendable>(
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

// (<*) :: f a -> f b -> f a
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <A: Sendable, B: Sendable>(
    _ lhs: AsyncStream<A>,
    _ rhs: AsyncStream<B>
) -> AsyncStream<A> {
    rhs *> lhs
}
