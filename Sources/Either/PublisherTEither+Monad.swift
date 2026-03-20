#if canImport(Combine)
import Combine
import Foundation
import FP

// PublisherTEither: outer = AnyPublisher, inner = Either
// Type: AnyPublisher<Either<L,A>, E>
// Haskell: ExceptT l (Publisher e)

/// flatMapT for AnyPublisher<Either<L,A>, E>
/// .left(l)  → emit .left(l)
/// .right(a) → flatten fn(a)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTPublisherEither<L, A, B, E: Error>(
    _ publisher: AnyPublisher<Either<L, A>, E>,
    _ fn: @escaping (A) -> AnyPublisher<Either<L, B>, E>
) -> AnyPublisher<Either<L, B>, E> {
    publisher.flatMap { either -> AnyPublisher<Either<L, B>, E> in
        either.match(
            caseLeft: { l in Just(.left(l)).setFailureType(to: E.self).eraseToAnyPublisher() },
            caseRight: { a in fn(a) }
        )
    }.eraseToAnyPublisher()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTPublisherEither<L, A, B, E: Error>(
    _ fn: @escaping (A) -> AnyPublisher<Either<L, B>, E>
) -> (AnyPublisher<Either<L, A>, E>) -> AnyPublisher<Either<L, B>, E> {
    { publisher in flatMapTPublisherEither(publisher, fn) }
}

#endif
