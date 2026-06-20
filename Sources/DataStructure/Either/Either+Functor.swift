// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Either {
    /// The `property` property.
    static func fmap<B1>(
        _ fn: @escaping @Sendable (B) -> B1
    ) -> @Sendable (Either<A, B>) -> Either<A, B1> {
        { $0.mapRight(fn) }
    }

    /// Declaration.
    func mapLeft<A1>(
        _ lf: @escaping @Sendable (A) -> A1
    ) -> Either<A1, B> {
        match(
            caseLeft: compose(lf, Either<A1, B>.left),
            caseRight: Either<A1, B>.right
        )
    }

    /// Declaration.
    func mapRight<B1>(
        _ rf: @escaping @Sendable (B) -> B1
    ) -> Either<A, B1> {
        match(
            caseLeft: Either<A, B1>.left,
            caseRight: compose(rf, Either<A, B1>.right)
        )
    }

    /// Declaration.
    func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> Either<A1, B1> {
        match(
            caseLeft: compose(lf, Either<A1, B1>.left),
            caseRight: compose(rf, Either<A1, B1>.right)
        )
    }

    /// The `property` property.
    static func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> (Either<A, B>) -> Either<A1, B1> {
        { $0.bimap(lf, rf) }
    }
}
