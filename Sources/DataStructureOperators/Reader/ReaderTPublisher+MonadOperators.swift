import DataStructure
#if canImport(Combine)
import CoreFP
import Combine
import CoreFPOperators

// MARK: - ReaderT + Publisher

// (>>-) :: m a -> (a -> m b) -> m b
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func >>- <Env, A, B, E: Error>(
    _ reader: Reader<Env, any Publisher<A, E>>,
    _ fn: @escaping (A) -> Reader<Env, any Publisher<B, E>>
) -> Reader<Env, any Publisher<B, E>> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func -<< <Env, A, B, E: Error>(
    _ fn: @escaping (A) -> Reader<Env, any Publisher<B, E>>,
    _ reader: Reader<Env, any Publisher<A, E>>
) -> Reader<Env, any Publisher<B, E>> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func >=> <Env, A, B, C, E: Error>(
    _ fn1: @escaping (A) -> Reader<Env, any Publisher<B, E>>,
    _ fn2: @escaping (B) -> Reader<Env, any Publisher<C, E>>
) -> (A) -> Reader<Env, any Publisher<C, E>> {
    { a in fn1(a).flatMapT(fn2) }
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <&> <Env, A, B, E: Error>(
    _ reader: Reader<Env, any Publisher<A, E>>,
    _ transform: @escaping (A) -> B
) -> Reader<Env, any Publisher<B, E>> where A: Sendable {
    reader.mapT(transform)
}

#endif
