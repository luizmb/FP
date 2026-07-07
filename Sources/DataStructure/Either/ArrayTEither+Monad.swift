// SPDX-License-Identifier: Apache-2.0
import Foundation

// ArrayTEither: outer = Array, inner = Either
// Type: [Either<L,A>] = Array<Either<L,A>>
// Haskell: ExceptT l []

public extension Array {
    /// flatMapT for [Either<L,A>]
    /// .left(l)  → [.left(l)]
    /// .right(a) → fn(a)
    func flatMapT<L, A, B>(_ fn: @escaping @Sendable (A) -> [Either<L, B>]) -> [Either<L, B>]
    where Element == Either<L, A> {
        flatMap { either in
            either.match(
                caseLeft: { l in [.left(l)] },
                caseRight: { a in fn(a) }
            )
        }
    }

    /// The `property` property.
    static func bindT<L, A, B>(
        _ fn: @escaping @Sendable (A) -> [Either<L, B>]
    ) -> ([Either<L, A>]) -> [Either<L, B>] {
        { arr in arr.flatMapT(fn) }
    }
}

/// Kleisli composition for `ArrayT + Either` (left-to-right)
/// (>=>) :: (a -> [Either<l,b>]) -> (b -> [Either<l,c>]) -> a -> [Either<l,c>]
public func kleisliT<L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> [Either<L, B>],
    _ fn2: @escaping @Sendable (B) -> [Either<L, C>]
) -> (A) -> [Either<L, C>] {
    { a in fn1(a).flatMapT(fn2) }
}
