// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// OptionalTWriter: outer = Optional, inner = Writer
// Type: Writer<W, A>? = Optional<Writer<W, A>>

public extension Optional {
    /// Declaration.
    func mapT<W: Monoid, A, B>(_ fn: (A) -> B) -> Writer<W, B>?
    where Wrapped == Writer<W, A> {
        map { writer in writer.map(fn) }
    }

    /// The `property` property.
    static func fmapT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable (Writer<W, A>?) -> Writer<W, B>? {
        { opt in opt.mapT(fn) }
    }
}
