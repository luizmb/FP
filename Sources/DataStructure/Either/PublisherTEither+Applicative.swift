// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
import Foundation

// PublisherTEither: outer = AnyPublisher, inner = Either
// Type: AnyPublisher<Either<L,A>, E>

/// `liftA2PublisherEither`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2PublisherEither<L: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (AnyPublisher<Either<L, A>, E>, AnyPublisher<Either<L, B>, E>) -> AnyPublisher<Either<L, C>, E> {
    { pubA, pubB in
        pubA.zip(pubB)
            .map { a, b in Either.liftA2(fn)(a, b) }
            .eraseToAnyPublisher()
    }
}

/// `seqRightPublisherEither`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightPublisherEither<L: Sendable, A: Sendable, B: Sendable, E: Error>(
    _ lhs: AnyPublisher<Either<L, A>, E>,
    _ rhs: AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, B>, E> {
    lhs.zip(rhs)
        .map { a, b in a.seqRight(b) }
        .eraseToAnyPublisher()
}

/// `seqLeftPublisherEither`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftPublisherEither<L: Sendable, A: Sendable, B: Sendable, E: Error>(
    _ lhs: AnyPublisher<Either<L, A>, E>,
    _ rhs: AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, A>, E> {
    lhs.zip(rhs)
        .map { a, b in a.seqLeft(b) }
        .eraseToAnyPublisher()
}

#endif
