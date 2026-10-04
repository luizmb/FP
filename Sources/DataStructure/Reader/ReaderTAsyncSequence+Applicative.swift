// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ReaderT + AsyncSequence
//
// ReaderT's applicative runs both readers against the same environment and combines the inner
// streams with the AsyncStream applicative, which is `ap` derived from the stream bind (ordered
// concat, cartesian), so `<*> == ap` for the whole stack. It is not zip; use `AsyncStream.zip`
// on the inner streams for pairing.

/// liftA2 for ReaderT AsyncStream
/// liftA2 f ra rb = ReaderT $ \env -> liftA2 f (ra env) (rb env)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2ReaderAsyncStream<Env, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, AsyncStream<A>>, Reader<Env, AsyncStream<B>>) -> Reader<Env, AsyncStream<C>>
where A: Sendable, B: Sendable, C: Sendable {
    { readerA, readerB in
        Reader { env in
            AsyncStream<C>.liftA2(fn)(readerA(env), readerB(env))
        }
    }
}

/// seqRight for ReaderT AsyncStream
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightReaderAsyncStream<Env, A, B>(
    _ lhs: Reader<Env, AsyncStream<A>>,
    _ rhs: Reader<Env, AsyncStream<B>>
) -> Reader<Env, AsyncStream<B>>
where A: Sendable, B: Sendable {
    liftA2ReaderAsyncStream { @Sendable (_: A, b: B) in b }(lhs, rhs)
}

/// seqLeft for ReaderT AsyncStream
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftReaderAsyncStream<Env, A, B>(
    _ lhs: Reader<Env, AsyncStream<A>>,
    _ rhs: Reader<Env, AsyncStream<B>>
) -> Reader<Env, AsyncStream<A>>
where A: Sendable, B: Sendable {
    liftA2ReaderAsyncStream { @Sendable (a: A, _: B) in a }(lhs, rhs)
}
