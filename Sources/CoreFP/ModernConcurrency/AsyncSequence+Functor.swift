import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncSequence {
    /// Curried fmap for functional composition
    static func fmap<T>(
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) -> @Sendable (Self) -> AsyncThrowingMapSequence<Self, T> {
        { sequence in
            sequence.map(transform)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    /// Curried fmap for AsyncStream
    static func fmap<T>(
        _ transform: @escaping @Sendable (Element) -> T
    ) -> @Sendable (AsyncStream<Element>) -> AsyncMapSequence<AsyncStream<Element>, T> {
        { stream in
            stream.map(transform)
        }
    }
}
