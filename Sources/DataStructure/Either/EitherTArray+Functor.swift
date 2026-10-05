// SPDX-License-Identifier: Apache-2.0
import CoreFP

// EitherTArray: outer = Either, inner = Array
// Type: Either<L, [A]>

extension Either {
    /// Maps the value inside the inner Array, leaving `.left` untouched.
    /// mapT :: (a -> b) -> Either l (array a) -> Either l (array b)
    func mapT<Inner, C>(_ fn: @escaping @Sendable (Inner) -> C) -> Either<A, [C]>
    where B == [Inner] {
        mapRight { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> C
    ) -> @Sendable (Either<A, [Inner]>) -> Either<A, [C]>
    where B == [Inner] {
        { $0.mapT(fn) }
    }
}
