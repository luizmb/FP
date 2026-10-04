// SPDX-License-Identifier: Apache-2.0
import CoreFP

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?>

public extension Either {
    /// Maps the value inside the inner Optional, leaving `.left` untouched.
    /// mapT :: (a -> b) -> Either l (optional a) -> Either l (optional b)
    func mapT<Inner, C>(_ fn: @escaping @Sendable (Inner) -> C) -> Either<A, C?>
    where B == Inner? {
        mapRight { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> C
    ) -> @Sendable (Either<A, Inner?>) -> Either<A, C?>
    where B == Inner? {
        { $0.mapT(fn) }
    }
}
