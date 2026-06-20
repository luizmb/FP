// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public extension Either {
        /// Declaration.
        func completion() -> Subscribers.Completion<A> where A: Error, B == Void {
            Subscribers.Completion.from(inverted())
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public extension Subscribers.Completion {
        /// Declaration.
        var either: SumTypeCopyStrategy<Either<A, B>, Either<B, A>> {
            .init(
                parallel: { Either.from(self) },
                crossover: { Either.from(self).inverted() }
            )
        }
    }

#endif
