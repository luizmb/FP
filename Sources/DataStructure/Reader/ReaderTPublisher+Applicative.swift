// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // ReaderT + Publisher
    //
    // The applicative is derived from the monad (`<*>` = `ap`), so it inherits the Publisher
    // ordered-concat bind: for each function, in order, the whole argument stream runs
    // (`[f, g] <*> [1, 2]` emits `[f(1), f(2), g(1), g(2)]`).

    /// apply for ReaderT Publisher
    /// mf <*> ma = mf >>= \f -> fmap f ma
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func applyReaderPublisher<Env, A: Sendable, B, E: Error>(
        _ readerF: Reader<Env, any Publisher<@Sendable (A) -> B, E>>,
        _ readerA: Reader<Env, any Publisher<A, E>>
    ) -> Reader<Env, any Publisher<B, E>> {
        readerF.flatMapT { f in readerA.mapT(f) }
    }

    /// liftA2 for ReaderT Publisher
    /// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func liftA2ReaderPublisher<Env, A: Sendable, B: Sendable, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (Reader<Env, any Publisher<A, E>>, Reader<Env, any Publisher<B, E>>) -> Reader<Env, any Publisher<C, E>> {
        { readerA, readerB in
            readerA.flatMapT { a in readerB.mapT { b in fn(a, b) } }
        }
    }

    /// seqRight for ReaderT Publisher
    /// ma *> mb = ma >>= \_ -> mb
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func seqRightReaderPublisher<Env, A, B, E: Error>(
        _ lhs: Reader<Env, any Publisher<A, E>>,
        _ rhs: Reader<Env, any Publisher<B, E>>
    ) -> Reader<Env, any Publisher<B, E>> {
        lhs.flatMapT { (_: A) in rhs }
    }

    /// seqLeft for ReaderT Publisher
    /// ma <* mb = ma >>= \a -> fmap (const a) mb
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func seqLeftReaderPublisher<Env, A: Sendable, B: Sendable, E: Error>(
        _ lhs: Reader<Env, any Publisher<A, E>>,
        _ rhs: Reader<Env, any Publisher<B, E>>
    ) -> Reader<Env, any Publisher<A, E>> {
        lhs.flatMapT { a in rhs.mapT { (_: B) in a } }
    }

#endif
