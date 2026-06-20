// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Reader {
    /// ReaderT + Optional
    func mapT<A, B>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, B?> where Output == A?, A: Sendable {
        mapReader(A?.fmap(fn))
    }

    /// The `property` property.
    static func fmap<A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, A?>) -> Reader<Environment, B?>
    where A: Sendable, Output == A? {
        { $0.mapT(fn) }
    }

    /// replaceOutputT :: Reader<e, a?> -> b -> Reader<e, b?>
    func replaceOutputT<A, B>(_ value: B) -> Reader<Environment, B?> where Output == A?, B: Sendable {
        mapReader { $0.map(const(value)) }
    }
}
