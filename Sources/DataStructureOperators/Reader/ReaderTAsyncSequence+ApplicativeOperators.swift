import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + AsyncSequence

// Note: The traditional apply operator (<*>) doesn't apply well to AsyncSequence
// because AsyncStream<(A) -> B> is not a practical type.
// Instead, we provide sequence operators that use liftA2 internally.

// (*>) :: Reader e (AsyncStream a) -> Reader e (AsyncStream b) -> Reader e (AsyncStream b)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <Env, A, B>(
    _ lhs: Reader<Env, AsyncStream<A>>,
    _ rhs: Reader<Env, AsyncStream<B>>
) -> Reader<Env, AsyncMapSequence<AsyncStream<(A, B)>, B>>
where A: Sendable, B: Sendable {
    seqRightReaderAsyncStream(lhs, rhs)
}

// (<*) :: Reader e (AsyncStream a) -> Reader e (AsyncStream b) -> Reader e (AsyncStream a)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <Env, A, B>(
    _ lhs: Reader<Env, AsyncStream<A>>,
    _ rhs: Reader<Env, AsyncStream<B>>
) -> Reader<Env, AsyncMapSequence<AsyncStream<(A, B)>, A>>
where A: Sendable, B: Sendable {
    seqLeftReaderAsyncStream(lhs, rhs)
}
