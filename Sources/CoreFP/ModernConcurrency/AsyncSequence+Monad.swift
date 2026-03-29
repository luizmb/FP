import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncSequence {
    /// Monadic bind (flatMap) for async sequences
    /// (>>=) :: m a -> (a -> m b) -> m b
    func bind<T: AsyncSequence>(
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) -> AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<Self, T>, T> {
        map(transform).flatMap(CoreFP.id)
    }

    /// Curried bind for functional composition
    static func bind<T: AsyncSequence>(
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) -> (Self) -> AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<Self, T>, T> {
        { sequence in
            sequence.bind(transform)
        }
    }

    /// Kleisli composition (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<B: AsyncSequence, C: AsyncSequence>(
        _ fn1: @escaping @Sendable (Element) async throws -> B,
        _ fn2: @escaping @Sendable (B.Element) async throws -> C
    ) -> (Element) async throws -> AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<B, C>, C> {
        { element in
            try await fn1(element).bind(fn2)
        }
    }

    /// Kleisli composition (right-to-left)
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<B: AsyncSequence, C: AsyncSequence>(
        _ fn2: @escaping @Sendable (B.Element) async throws -> C,
        _ fn1: @escaping @Sendable (Element) async throws -> B
    ) -> (Element) async throws -> AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<B, C>, C> {
        { element in
            try await fn1(element).bind(fn2)
        }
    }
}
