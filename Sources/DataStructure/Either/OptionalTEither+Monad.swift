// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>
// Haskell: ExceptT l Maybe

public extension Optional {
    /// flatMapT for Optional<Either<L,A>>
    /// nil         → nil
    /// .some(.left(l))  → .some(.left(l))
    /// .some(.right(a)) → fn(a)
    func flatMapT<L, A, B>(_ fn: @escaping @Sendable (A) -> Either<L, B>?) -> Either<L, B>? where Wrapped == Either<L, A> {
        flatMap { either in
            either.match(
                caseLeft: { l in .some(.left(l)) },
                caseRight: { a in fn(a) }
            )
        }
    }

    /// The `property` property.
    static func bindT<L, A, B>(_ fn: @escaping @Sendable (A) -> Either<L, B>?) -> @Sendable (Either<L, A>?) -> Either<L, B>? {
        { opt in opt.flatMapT(fn) }
    }
}

/// Kleisli composition for `OptionalT + Either` (left-to-right)
/// (>=>) :: (a -> Either<l,b>?) -> (b -> Either<l,c>?) -> a -> Either<l,c>?
public func kleisliT<L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, B>?,
    _ fn2: @escaping @Sendable (B) -> Either<L, C>?
) -> (A) -> Either<L, C>? {
    { a in fn1(a).flatMapT(fn2) }
}
