// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTNonEmpty: outer = Validation, inner = NonEmpty
// Type: Validation<E, NonEmpty<A>>

public extension Validation {
    /// Maps the value inside the inner NonEmpty, leaving `.failure` untouched.
    /// mapT :: (a -> b) -> Validation e (nonempty a) -> Validation e (nonempty b)
    func mapT<Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        mapSuccess { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, NonEmpty<Inner>>) -> Validation<E, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        { $0.mapT(fn) }
    }
}
