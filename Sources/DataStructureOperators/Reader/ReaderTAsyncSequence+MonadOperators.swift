// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + AsyncSequence

// (>>=) :: m a -> (a -> m b) -> m b
/// `>>-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <Env, A, B: AsyncSequence>(
    _ reader: Reader<Env, AsyncStream<A>>,
    _ fn: @escaping @Sendable (A) async throws -> Reader<Env, B>
) -> Reader<Env, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>, B>, B>>
where A: Sendable, Env: Sendable {
    reader.flatMapT(fn)
}

// (=<<) :: (a -> m b) -> m a -> m b
/// `-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <Env, A, B: AsyncSequence>(
    _ fn: @escaping @Sendable (A) async throws -> Reader<Env, B>,
    _ reader: Reader<Env, AsyncStream<A>>
) -> Reader<Env, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>, B>, B>>
where A: Sendable, Env: Sendable {
    reader >>- fn
}
