// SPDX-License-Identifier: Apache-2.0
import DataStructure
#if canImport(Combine)
import Combine
import CoreFPOperators

// PublisherTEither: AnyPublisher<Either<L,A>, E>

/// `*>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <L: Sendable, A: Sendable, B: Sendable, E: Error>(
    _ lhs: AnyPublisher<Either<L, A>, E>,
    _ rhs: AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, B>, E> {
    seqRightPublisherEither(lhs, rhs)
}

/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <L: Sendable, A: Sendable, B: Sendable, E: Error>(
    _ lhs: AnyPublisher<Either<L, A>, E>,
    _ rhs: AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, A>, E> {
    seqLeftPublisherEither(lhs, rhs)
}
#endif
