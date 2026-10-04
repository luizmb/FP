// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // PublisherTArray: outer = Publisher, inner = Array
    // Type: AnyPublisher<[A], Failure>

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public extension Publisher {
        /// Maps the value inside every emitted Array.
        /// mapT :: (a -> b) -> Publisher (array a) e -> Publisher (array b) e
        func mapT<Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> AnyPublisher<[B], Failure>
        where Output == [Inner] {
            map { $0.map(fn) }.eraseToAnyPublisher()
        }

        /// Curried, point-free form of ``mapT(_:)``.
        static func fmapT<Inner, B>(
            _ fn: @escaping @Sendable (Inner) -> B
        ) -> @Sendable (AnyPublisher<[Inner], Failure>) -> AnyPublisher<[B], Failure>
        where Output == [Inner] {
            { $0.mapT(fn) }
        }
    }

#endif
