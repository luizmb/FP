// SPDX-License-Identifier: Apache-2.0
import CoreFP

// EitherTValidation: outer = Either, inner = Validation
// Type: Either<L, Validation<E, A>>

public extension Either {
    /// Maps the value inside the inner Validation, leaving `.left` untouched.
    /// mapT :: (a -> b) -> Either l (validation a) -> Either l (validation b)
    func mapT<E: Semigroup, Inner, C>(_ fn: @escaping @Sendable (Inner) -> C) -> Either<A, Validation<E, C>>
    where B == Validation<E, Inner> {
        mapRight { $0.mapSuccess(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<E: Semigroup, Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> C
    ) -> @Sendable (Either<A, Validation<E, Inner>>) -> Either<A, Validation<E, C>>
    where B == Validation<E, Inner> {
        { $0.mapT(fn) }
    }
}
