// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTEither: outer = Validation, inner = Either
// Type: Validation<E, Either<L, A>>

public extension Validation {
    /// Maps the value inside the inner Either, leaving `.failure` untouched.
    /// mapT :: (a -> b) -> Validation e (either a) -> Validation e (either b)
    func mapT<L, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, Either<L, B>>
    where A == Either<L, Inner> {
        mapSuccess { $0.mapRight(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, Either<L, Inner>>) -> Validation<E, Either<L, B>>
    where A == Either<L, Inner> {
        { $0.mapT(fn) }
    }
}
