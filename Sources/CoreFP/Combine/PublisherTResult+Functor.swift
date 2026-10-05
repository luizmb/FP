// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTResult: outer = Publisher, inner = Result
    // Type: AnyPublisher<Result<A, E2>, Failure>

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    extension Publisher {
        /// Maps the value inside every emitted Result.
        /// mapT :: (a -> b) -> Publisher (result a) e -> Publisher (result b) e
        func mapT<Inner, B, E2: Error>(_ fn: @escaping @Sendable (Inner) -> B) -> AnyPublisher<Result<B, E2>, Failure>
        where Output == Result<Inner, E2> {
            map { $0.map(fn) }.eraseToAnyPublisher()
        }

        /// Curried, point-free form of ``mapT(_:)``.
        static func fmapT<Inner, B, E2: Error>(
            _ fn: @escaping @Sendable (Inner) -> B
        ) -> @Sendable (AnyPublisher<Result<Inner, E2>, Failure>) -> AnyPublisher<Result<B, E2>, Failure>
        where Output == Result<Inner, E2> {
            { $0.mapT(fn) }
        }
    }

#endif
