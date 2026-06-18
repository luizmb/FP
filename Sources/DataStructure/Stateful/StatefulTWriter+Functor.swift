// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// StatefulTWriter: outer = Stateful, inner = Writer
// Type: Stateful<S, Writer<W, A>>

public extension Stateful {
    /// Declaration.
    func mapT<W: Monoid, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Stateful<S, Writer<W, B>>
    where A == Writer<W, Inner> {
        mapStateful(Writer<W, Inner>.fmap(fn))
    }

    /// The `property` property.
    static func fmapT<W: Monoid, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Stateful<S, Writer<W, Inner>>) -> Stateful<S, Writer<W, B>>
    where A == Writer<W, Inner> {
        { $0.mapT(fn) }
    }
}
