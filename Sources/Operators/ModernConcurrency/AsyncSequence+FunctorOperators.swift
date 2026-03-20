import Foundation
import FP

// (<$>) :: Functor f => (a -> b) -> f a -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <S: AsyncSequence, T>(
    _ transform: @escaping @Sendable (S.Element) async throws -> T,
    _ sequence: S
) -> AsyncThrowingMapSequence<S, T> where T: Sendable {
    sequence.map(transform)
}

// ($>) :: f a -> b -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func £> <S: AsyncSequence, T: Sendable>(
    _ sequence: S,
    _ value: T
) -> AsyncThrowingMapSequence<S, T> {
    sequence.map(const(value))
}

// (<$) :: b -> f a -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£ <S: AsyncSequence, T: Sendable>(
    _ value: T,
    _ sequence: S
) -> AsyncThrowingMapSequence<S, T> {
    sequence £> value
}
