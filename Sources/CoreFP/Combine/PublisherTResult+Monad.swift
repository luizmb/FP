#if canImport(Combine)
import Combine
import Foundation

// PublisherTResult: outer = AnyPublisher, inner = Result
// Type: AnyPublisher<Result<A,E2>, E>

/// flatMapT for AnyPublisher<Result<A,E2>, E>
/// .failure(e) → emit .failure(e)
/// .success(a) → apply fn, flatten
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTPublisherResult<A, B, E: Error, E2: Error>(
    _ publisher: AnyPublisher<Result<A, E2>, E>,
    _ fn: @escaping @Sendable (A) -> AnyPublisher<Result<B, E2>, E>
) -> AnyPublisher<Result<B, E2>, E> {
    publisher
        .flatMap { result -> AnyPublisher<Result<B, E2>, E> in
            switch result {
            case .failure(let e2):
                return Just(.failure(e2)).setFailureType(to: E.self).eraseToAnyPublisher()
            case .success(let a):
                return fn(a)
            }
        }
        .eraseToAnyPublisher()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTPublisherResult<A, B, E: Error, E2: Error>(
    _ fn: @escaping @Sendable (A) -> AnyPublisher<Result<B, E2>, E>
) -> (AnyPublisher<Result<A, E2>, E>) -> AnyPublisher<Result<B, E2>, E> {
    { publisher in flatMapTPublisherResult(publisher, fn) }
}

#endif
