#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Curried version of Combine's native flatMap for functional composition
    /// (>>=) :: m a -> (a -> m b) -> m b
    static func bind<A1, P: Publisher>(
        _ fn: @escaping @Sendable (A) -> P
    ) -> (any Publisher<A, Failure>) -> any Publisher<A1, Failure>
    where P.Output == A1, P.Failure == Failure {
        { publisher in
            publisher.eraseToAnyPublisher().flatMap(fn).eraseToAnyPublisher()
        }
    }

    /// Kleisli composition (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<A0, A1, P1: Publisher, P2: Publisher>(
        _ fn1: @escaping @Sendable (A0) -> P1,
        _ fn2: @escaping @Sendable (A) -> P2
    ) -> (A0) -> any Publisher<A1, Failure>
    where P1.Output == A, P1.Failure == Failure, P2.Output == A1, P2.Failure == Failure {
        { a0 in
            fn1(a0).eraseToAnyPublisher().flatMap(fn2).eraseToAnyPublisher()
        }
    }

    /// Kleisli composition (right-to-left)
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<A0, A1, P1: Publisher, P2: Publisher>(
        _ fn2: @escaping @Sendable (A) -> P2,
        _ fn1: @escaping @Sendable (A0) -> P1
    ) -> (A0) -> any Publisher<A1, Failure>
    where P1.Output == A, P1.Failure == Failure, P2.Output == A1, P2.Failure == Failure {
        { a0 in
            fn1(a0).eraseToAnyPublisher().flatMap(fn2).eraseToAnyPublisher()
        }
    }
}

#endif
