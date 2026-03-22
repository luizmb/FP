import Foundation
import CoreFP

// (>>-) :: m a -> (a -> m b) -> m b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <S: AsyncSequence, T: AsyncSequence>(
    _ sequence: S,
    _ transform: @escaping @Sendable (S.Element) async throws -> T
) -> AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<S, T>, T> {
    sequence.bind(transform)
}

// (-<<) :: (a -> m b) -> m a -> m b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <S: AsyncSequence, T: AsyncSequence>(
    _ transform: @escaping @Sendable (S.Element) async throws -> T,
    _ sequence: S
) -> AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<S, T>, T> {
    sequence >>- transform
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >=> <A, B: AsyncSequence, C: AsyncSequence>(
    _ fn1: @escaping @Sendable (A) async throws -> B,
    _ fn2: @escaping @Sendable (B.Element) async throws -> C
) -> (A) async throws -> AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<B, C>, C> {
    { a in
        try await fn1(a).bind(fn2)
    }
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&> <S: AsyncSequence, T>(
    _ sequence: S,
    _ transform: @escaping @Sendable (S.Element) async throws -> T
) -> AsyncThrowingMapSequence<S, T> {
    sequence.map(transform)
}
