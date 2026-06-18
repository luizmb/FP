// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public extension Publisher {
        /// Declaration.
        typealias A = Output
        /// Declaration.
        typealias B = Failure

        /// The `property` property.
        static func left(_ a: A) -> any Publisher {
            Result<A, B>.success(a).publisher
        }

        /// The `property` property.
        static func right(_ b: B) -> any Publisher {
            Result<A, B>.failure(b).publisher
        }

        /// The `property` property.
        static func fmap<A1>(
            _ fn: @escaping @Sendable (A) -> A1
        ) -> @Sendable (any Publisher<A, Failure>) -> any Publisher<A1, Failure> {
            { $0.eraseToAnyPublisher().map(fn) }
        }

        /// Declaration.
        func mapLeft<A1>(
            _ lf: @escaping @Sendable (Output) -> A1
        ) -> any Publisher<A1, Failure> {
            map(lf)
        }

        /// Declaration.
        func mapRight<B1: Error>(
            _ rf: @escaping @Sendable (B) -> B1
        ) -> any Publisher<A, B1> {
            mapError(rf)
        }

        /// Declaration.
        func bimap<A1, B1: Error>(
            _ lf: @escaping @Sendable (A) -> A1,
            _ rf: @escaping @Sendable (B) -> B1
        ) -> any Publisher<A1, B1> {
            map(lf)
                .mapError(rf)
        }

        /// replaceOutput :: Publisher<a, e> -> b -> Publisher<b, e>
        func replaceOutput<A1>(_ value: A1) -> any Publisher<A1, Failure> {
            eraseToAnyPublisher().map(const(value))
        }
    }

#endif
