// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTStateful: outer = Optional, inner = Stateful
// Type: Stateful<S, A>? = Optional<Stateful<S, A>>

public extension Optional {
    /// Declaration.
    func mapT<S, A, B>(_ fn: @escaping @Sendable (A) -> B) -> Stateful<S, B>?
    where Wrapped == Stateful<S, A> {
        map { stateful in stateful.map(fn) }
    }

    /// The `property` property.
    static func fmapT<S, A, B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable (Stateful<S, A>?) -> Stateful<S, B>? {
        { opt in opt.mapT(fn) }
    }
}
