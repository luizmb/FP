// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTArray: outer = Validation, inner = Array
// Type: Validation<E, [A]>

extension Validation {
    /// Maps the value inside the inner Array, leaving `.failure` untouched.
    /// mapT :: (a -> b) -> Validation e (array a) -> Validation e (array b)
    func mapT<Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, [B]>
    where A == [Inner] {
        mapSuccess { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, [Inner]>) -> Validation<E, [B]>
    where A == [Inner] {
        { $0.mapT(fn) }
    }
}
