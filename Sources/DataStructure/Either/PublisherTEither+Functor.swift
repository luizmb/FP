// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTEither: outer = Publisher, inner = Either
    // Type: AnyPublisher<Either<L, A>, Failure>

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    extension Publisher {
        /// Maps the value inside every emitted Either.
        /// mapT :: (a -> b) -> Publisher (either a) e -> Publisher (either b) e
        func mapT<L, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> AnyPublisher<Either<L, B>, Failure>
        where Output == Either<L, Inner> {
            map { $0.mapRight(fn) }.eraseToAnyPublisher()
        }

        /// Curried, point-free form of ``mapT(_:)``.
        static func fmapT<L, Inner, B>(
            _ fn: @escaping @Sendable (Inner) -> B
        ) -> @Sendable (AnyPublisher<Either<L, Inner>, Failure>) -> AnyPublisher<Either<L, B>, Failure>
        where Output == Either<L, Inner> {
            { $0.mapT(fn) }
        }
    }

#endif
