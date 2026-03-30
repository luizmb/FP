#if canImport(Combine)
import Combine
import Foundation

// PublisherTEither: outer = AnyPublisher, inner = Either
// Type: AnyPublisher<Either<L,A>, E>

/// mapT for AnyPublisher<Either<L,A>, E> — maps over the inner Either's right side
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func mapTPublisherEither<L, A, B, E: Error>(
    _ fn: @escaping (A) -> B,
    _ publisher: AnyPublisher<Either<L, A>, E>
) -> AnyPublisher<Either<L, B>, E> {
    publisher.map { either in either.mapRight(fn) }.eraseToAnyPublisher()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func fmapTPublisherEither<L, A, B, E: Error>(
    _ fn: @escaping (A) -> B
) -> (AnyPublisher<Either<L, A>, E>) -> AnyPublisher<Either<L, B>, E> {
    { publisher in mapTPublisherEither(fn, publisher) }
}

#endif
