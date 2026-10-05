// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTWriter: outer = Validation, inner = Writer
// Type: Validation<E, Writer<W, A>>

extension Validation {
    /// Maps the value inside the inner Writer, leaving `.failure` untouched.
    /// mapT :: (a -> b) -> Validation e (writer a) -> Validation e (writer b)
    func mapT<W: Monoid, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, Writer<W, B>>
    where A == Writer<W, Inner> {
        mapSuccess { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<W: Monoid, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, Writer<W, Inner>>) -> Validation<E, Writer<W, B>>
    where A == Writer<W, Inner> {
        { $0.mapT(fn) }
    }
}
