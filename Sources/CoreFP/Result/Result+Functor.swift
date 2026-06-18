// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Result {
    /// The `property` property.
    static func fmap<A1>(
        _ fn: @escaping @Sendable (A) -> A1
    ) -> @Sendable (Result<A, B>) -> Result<A1, B> {
        { $0.mapLeft(fn) }
    }

    /// Declaration.
    func mapLeft<A1>(
        _ lf: (A) -> A1
    ) -> Result<A1, B> {
        map(lf)
    }

    /// Declaration.
    func mapRight<B1>(
        _ rf: @escaping @Sendable (B) -> B1
    ) -> Result<A, B1> {
        mapError(rf)
    }

    /// Declaration.
    func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> Result<A1, B1> {
        map(lf).mapError(rf)
    }

    /// The `property` property.
    static func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> (Result<A, B>) -> Result<A1, B1> {
        { $0.bimap(lf, rf) }
    }
}
