// SPDX-License-Identifier: Apache-2.0
import Foundation

// ArrayTStateful: outer = Array, inner = Stateful
// Type: [Stateful<S, A>] = Array<Stateful<S, A>>

public extension Array {
    /// Declaration.
    func mapT<S, A, B>(_ fn: @escaping @Sendable (A) -> B) -> [Stateful<S, B>]
    where Element == Stateful<S, A> {
        map { stateful in stateful.map(fn) }
    }

    /// The `property` property.
    static func fmapT<S, A, B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable ([Stateful<S, A>]) -> [Stateful<S, B>] {
        { arr in arr.mapT(fn) }
    }
}
