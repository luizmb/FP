#if canImport(Combine)
import Combine
import FP
import Either
import Operators

// PublisherTEither: AnyPublisher<Either<L,A>, E>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <L, A, B, E: Error>(
    _ lhs: AnyPublisher<Either<L, A>, E>,
    _ rhs: AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, B>, E> {
    seqRightPublisherEither(lhs, rhs)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <L, A, B, E: Error>(
    _ lhs: AnyPublisher<Either<L, A>, E>,
    _ rhs: AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, A>, E> {
    seqLeftPublisherEither(lhs, rhs)
}
#endif
