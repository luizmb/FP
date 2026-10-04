// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTStateful: outer = Validation, inner = Stateful
// Type: Validation<E, Stateful<S, A>>

public extension Validation {
    /// Maps the value inside the inner Stateful, leaving `.failure` untouched.
    /// mapT :: (a -> b) -> Validation e (stateful a) -> Validation e (stateful b)
    func mapT<S, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, Stateful<S, B>>
    where A == Stateful<S, Inner> {
        mapSuccess { $0.mapStateful(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<S, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, Stateful<S, Inner>>) -> Validation<E, Stateful<S, B>>
    where A == Stateful<S, Inner> {
        { $0.mapT(fn) }
    }
}
