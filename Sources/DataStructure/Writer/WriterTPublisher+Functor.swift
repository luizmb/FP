// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    public extension Writer {
        // WriterT + Publisher — Writer<W, any Publisher<A, E>>

        /// Declaration.
        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        func mapT<Inner, B, E: Error>(_ fn: @escaping @Sendable (Inner) -> B) -> Writer<W, any Publisher<B, E>>
        where A == any Publisher<Inner, E>, Inner: Sendable {
            mapWriter(AnyPublisher<Inner, E>.fmap(fn))
        }

        /// The `property` property.
        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        static func fmapT<Inner, B, E: Error>(
            _ fn: @escaping @Sendable (Inner) -> B
        ) -> @Sendable (Writer<W, any Publisher<Inner, E>>) -> Writer<W, any Publisher<B, E>>
        where Inner: Sendable, A == any Publisher<Inner, E> {
            { $0.mapT(fn) }
        }
    }

#endif
