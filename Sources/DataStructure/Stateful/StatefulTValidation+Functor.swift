// SPDX-License-Identifier: Apache-2.0
import CoreFP

// StatefulTValidation: outer = Stateful, inner = Validation
// Type: Stateful<S, Validation<E, A>>

extension Stateful {
    /// Maps the success value inside the inner Validation, threading the state unchanged.
    /// mapT :: (a -> b) -> Stateful s (Validation e a) -> Stateful s (Validation e b)
    func mapT<E: Semigroup, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Stateful<S, Validation<E, B>>
    where A == Validation<E, Inner> {
        mapStateful(Validation<E, Inner>.fmap(fn))
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<E: Semigroup, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Stateful<S, Validation<E, Inner>>) -> Stateful<S, Validation<E, B>>
    where A == Validation<E, Inner> {
        { $0.mapT(fn) }
    }
}
