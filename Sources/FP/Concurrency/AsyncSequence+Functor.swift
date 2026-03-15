import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncSequence {
    /// Map over an async sequence
    /// fmap :: (a -> b) -> f a -> f b
    func fmap<T>(_ transform: @escaping @Sendable (Element) async throws -> T) -> AsyncThrowingMapSequence<Self, T> {
        map(transform)
    }

    /// Curried fmap for functional composition
    static func fmap<T>(
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) -> (Self) -> AsyncThrowingMapSequence<Self, T> {
        { sequence in
            sequence.map(transform)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    /// Map over an async stream (non-throwing version)
    /// fmap :: (a -> b) -> f a -> f b
    func fmap<T>(_ transform: @escaping @Sendable (Element) -> T) -> AsyncMapSequence<AsyncStream<Element>, T> {
        map(transform)
    }

    /// Curried fmap for AsyncStream
    static func fmap<T>(
        _ transform: @escaping @Sendable (Element) -> T
    ) -> (AsyncStream<Element>) -> AsyncMapSequence<AsyncStream<Element>, T> {
        { stream in
            stream.map(transform)
        }
    }
}
