// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTOptional: outer = Validation, inner = Optional
// Type: Validation<E, A?>

extension Validation {
    /// Maps the value inside the inner Optional, leaving `.failure` untouched.
    /// mapT :: (a -> b) -> Validation e (optional a) -> Validation e (optional b)
    func mapT<Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, B?>
    where A == Inner? {
        mapSuccess { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, Inner?>) -> Validation<E, B?>
    where A == Inner? {
        { $0.mapT(fn) }
    }
}
