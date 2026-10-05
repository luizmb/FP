// SPDX-License-Identifier: Apache-2.0
import CoreFP

// EitherTNonEmpty: outer = Either, inner = NonEmpty
// Type: Either<L, NonEmpty<A>>

extension Either {
    /// Maps the value inside the inner NonEmpty, leaving `.left` untouched.
    /// mapT :: (a -> b) -> Either l (nonempty a) -> Either l (nonempty b)
    func mapT<Inner, C>(_ fn: @escaping @Sendable (Inner) -> C) -> Either<A, NonEmpty<C>>
    where B == NonEmpty<Inner> {
        mapRight { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> C
    ) -> @Sendable (Either<A, NonEmpty<Inner>>) -> Either<A, NonEmpty<C>>
    where B == NonEmpty<Inner> {
        { $0.mapT(fn) }
    }
}
