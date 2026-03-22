#if canImport(Combine)
import Combine
import Foundation
import CoreFP

// PublisherTEither: outer = AnyPublisher, inner = Either
// Type: AnyPublisher<Either<L,A>, E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2PublisherEither<L, A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (AnyPublisher<Either<L, A>, E>, AnyPublisher<Either<L, B>, E>) -> AnyPublisher<Either<L, C>, E> {
    { pubA, pubB in
        pubA.zip(pubB)
            .map { a, b in Either.liftA2(fn)(a, b) }
            .eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightPublisherEither<L, A, B, E: Error>(
    _ lhs: AnyPublisher<Either<L, A>, E>,
    _ rhs: AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, B>, E> {
    lhs.zip(rhs)
        .map { a, b in a.seqRight(b) }
        .eraseToAnyPublisher()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftPublisherEither<L, A, B, E: Error>(
    _ lhs: AnyPublisher<Either<L, A>, E>,
    _ rhs: AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, A>, E> {
    lhs.zip(rhs)
        .map { a, b in a.seqLeft(b) }
        .eraseToAnyPublisher()
}

#endif
