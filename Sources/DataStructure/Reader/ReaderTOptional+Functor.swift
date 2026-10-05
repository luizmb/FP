// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

extension Reader {
    /// ReaderT + Optional
    func mapT<A, B>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, B?> where Output == A?, A: Sendable {
        mapReader(A?.fmap(fn))
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, A?>) -> Reader<Environment, B?>
    where A: Sendable, Output == A? {
        { $0.mapT(fn) }
    }
}
