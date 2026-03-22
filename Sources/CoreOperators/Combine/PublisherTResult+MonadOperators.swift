#if canImport(Combine)
import Combine
import Core

// PublisherTResult: AnyPublisher<Result<A,E2>, E>

// (>>-) :: AnyPublisher<Result<a,e2>,e> -> (a -> AnyPublisher<Result<b,e2>,e>) -> AnyPublisher<Result<b,e2>,e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <A, B, E: Error, E2: Error>(
    _ pub: AnyPublisher<Result<A, E2>, E>,
    _ fn: @escaping (A) -> AnyPublisher<Result<B, E2>, E>
) -> AnyPublisher<Result<B, E2>, E> {
    flatMapTPublisherResult(pub, fn)
}

// (-<<) :: (a -> AnyPublisher<Result<b,e2>,e>) -> AnyPublisher<Result<a,e2>,e> -> AnyPublisher<Result<b,e2>,e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <A, B, E: Error, E2: Error>(
    _ fn: @escaping (A) -> AnyPublisher<Result<B, E2>, E>,
    _ pub: AnyPublisher<Result<A, E2>, E>
) -> AnyPublisher<Result<B, E2>, E> {
    flatMapTPublisherResult(pub, fn)
}
#endif
