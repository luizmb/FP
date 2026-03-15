#if canImport(Combine)
import Combine
import FP
import Foundation

// (>>-) :: m a -> (a -> m b) -> m b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <A, A1, B: Error, P: Publisher>(
    _ publisher: any Publisher<A, B>,
    _ fn: @escaping (A) -> P
) -> any Publisher<A1, B>
where P.Output == A1, P.Failure == B {
    AnyPublisher<A, B>.bind(fn)(publisher)
}

// (-<<) :: (a -> m b) -> m a -> m b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <A, A1, B: Error, P: Publisher>(
    _ fn: @escaping (A) -> P,
    _ publisher: any Publisher<A, B>
) -> any Publisher<A1, B>
where P.Output == A1, P.Failure == B {
    AnyPublisher<A, B>.bind(fn)(publisher)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >=> <A0, A, A1, B: Error, P1: Publisher, P2: Publisher>(
    _ fn1: @escaping (A0) -> P1,
    _ fn2: @escaping (A) -> P2
) -> (A0) -> any Publisher<A1, B>
where P1.Output == A, P1.Failure == B, P2.Output == A1, P2.Failure == B {
    AnyPublisher<A, B>.kleisli(fn1, fn2)
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&> <A, A1, B: Error>(
    _ publisher: any Publisher<A, B>,
    _ transform: @escaping (A) -> A1
) -> any Publisher<A1, B> {
    AnyPublisher<A, B>.fmap(transform)(publisher)
}

#endif
