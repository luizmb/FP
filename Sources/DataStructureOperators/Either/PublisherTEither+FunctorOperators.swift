import DataStructure
#if canImport(Combine)
import Combine
import CoreFP
import CoreFPOperators

// PublisherTEither: AnyPublisher<Either<L,A>, E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <L, A, B, E: Error>(_ fn: @escaping (A) -> B, _ pub: AnyPublisher<Either<L, A>, E>) -> AnyPublisher<Either<L, B>, E> {
    mapTPublisherEither(fn, pub)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <L, A, B, E: Error>(_ pub: AnyPublisher<Either<L, A>, E>, _ fn: @escaping (A) -> B) -> AnyPublisher<Either<L, B>, E> {
    mapTPublisherEither(fn, pub)
}
#endif
