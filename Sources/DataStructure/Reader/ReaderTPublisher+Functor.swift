// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    public extension Reader {
        // ReaderT + Publisher
        /// Declaration.
        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        func mapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, any Publisher<B, E>>
        where Output == any Publisher<A, E>, A: Sendable {
            mapReader(AnyPublisher<A, E>.fmap(fn))
        }

        /// Curried, point-free form of ``mapT(_:)``.
        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        static func fmapT<A, B, E: Error>(
            _ fn: @escaping @Sendable (A) -> B
        ) -> @Sendable (Reader<Environment, any Publisher<A, E>>) -> Reader<Environment, any Publisher<B, E>>
        where A: Sendable, Output == any Publisher<A, E> {
            { $0.mapT(fn) }
        }
    }

#endif
