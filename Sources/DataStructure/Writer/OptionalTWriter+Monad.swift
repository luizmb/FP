// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// OptionalTWriter: outer = Optional, inner = Writer
// Type: Writer<W, A>? = Optional<Writer<W, A>>

public extension Optional {
    /// flatMapT :: Writer<w, a>? -> (a -> Writer<w, b>) -> Writer<w, b>?
    /// nil             → nil
    /// some(writer)    → some(writer.flatMap(fn))
    func flatMapT<W: Monoid, A, B>(_ fn: (A) -> Writer<W, B>) -> Writer<W, B>?
    where Wrapped == Writer<W, A> {
        map { writer in writer.flatMap(fn) }
    }

    /// The `property` property.
    static func bindT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> Writer<W, B>) -> @Sendable (Writer<W, A>?) -> Writer<W, B>? {
        { opt in opt.flatMapT(fn) }
    }
}
