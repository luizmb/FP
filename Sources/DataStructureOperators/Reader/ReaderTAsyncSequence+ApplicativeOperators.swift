// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + AsyncSequence

// Note: there is no `<*>` here because `Reader<Env, AsyncStream<(A) -> B>>` is rarely practical;
// the sequence operators below use the bind-derived (concat) liftA2, not zip.

// (*>) :: Reader e (AsyncStream a) -> Reader e (AsyncStream b) -> Reader e (AsyncStream b)
/// `*>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <Env, A, B>(
    _ lhs: Reader<Env, AsyncStream<A>>,
    _ rhs: Reader<Env, AsyncStream<B>>
) -> Reader<Env, AsyncStream<B>>
where A: Sendable, B: Sendable {
    seqRightReaderAsyncStream(lhs, rhs)
}

// (<*) :: Reader e (AsyncStream a) -> Reader e (AsyncStream b) -> Reader e (AsyncStream a)
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <Env, A, B>(
    _ lhs: Reader<Env, AsyncStream<A>>,
    _ rhs: Reader<Env, AsyncStream<B>>
) -> Reader<Env, AsyncStream<A>>
where A: Sendable, B: Sendable {
    seqLeftReaderAsyncStream(lhs, rhs)
}
