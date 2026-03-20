#if canImport(Combine)
import Combine
import Foundation

// PublisherTArray: outer = AnyPublisher, inner = Array
// Type: AnyPublisher<[A], E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func mapTPublisherArray<A, B, E: Error>(
    _ fn: @escaping (A) -> B,
    _ publisher: AnyPublisher<[A], E>
) -> AnyPublisher<[B], E> {
    publisher.map { arr in arr.map(fn) }.eraseToAnyPublisher()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func fmapTPublisherArray<A, B, E: Error>(
    _ fn: @escaping (A) -> B
) -> (AnyPublisher<[A], E>) -> AnyPublisher<[B], E> {
    { publisher in mapTPublisherArray(fn, publisher) }
}

#endif
