// SPDX-License-Identifier: Apache-2.0
import DataStructure
#if canImport(Combine)
import Combine
import CoreFPOperators

// PublisherTEither: AnyPublisher<Either<L,A>, E>

/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <L, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> B,
    _ pub: AnyPublisher<Either<L, A>, E>
) -> AnyPublisher<Either<L, B>, E> {
    mapTPublisherEither(fn, pub)
}

/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <L, A, B, E: Error>(
    _ pub: AnyPublisher<Either<L, A>, E>,
    _ fn: @escaping @Sendable (A) -> B) -> AnyPublisher<Either<L, B>, E> {
    mapTPublisherEither(fn, pub)
}
#endif
