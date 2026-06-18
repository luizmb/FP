// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ArrayTWriter: outer = Array, inner = Writer
// Type: [Writer<W, A>]

public extension Array {
    /// Declaration.
    func mapT<W: Monoid, A, B>(_ fn: (A) -> B) -> [Writer<W, B>]
    where Element == Writer<W, A> {
        map { writer in writer.map(fn) }
    }

    /// The `property` property.
    static func fmapT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable ([Writer<W, A>]) -> [Writer<W, B>] {
        { arr in arr.mapT(fn) }
    }
}
