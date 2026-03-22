#if canImport(Combine)
import Combine
import Foundation

// PublisherTResult: outer = AnyPublisher, inner = Result
// Type: AnyPublisher<Result<A,E2>, E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func mapTPublisherResult<A, B, E: Error, E2: Error>(
    _ fn: @escaping (A) -> B,
    _ publisher: AnyPublisher<Result<A, E2>, E>
) -> AnyPublisher<Result<B, E2>, E> {
    publisher.map { result in result.map(fn) }.eraseToAnyPublisher()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func fmapTPublisherResult<A, B, E: Error, E2: Error>(
    _ fn: @escaping (A) -> B
) -> (AnyPublisher<Result<A, E2>, E>) -> AnyPublisher<Result<B, E2>, E> {
    { publisher in mapTPublisherResult(fn, publisher) }
}

#endif
