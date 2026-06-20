// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<*>) :: Either<l, Validation<e,(a->b)>> -> Either<l, Validation<e,a>> -> Either<l, Validation<e,b>>
public func <*> <L, E: Semigroup, A, B>(
    _ fns: Either<L, Validation<E, @Sendable (A) -> B>>,
    _ values: Either<L, Validation<E, A>>
) -> Either<L, Validation<E, B>> {
    applyEitherValidation(fns, values)
}

/// (*>) :: Either<l, Validation<e,a>> -> Either<l, Validation<e,b>> -> Either<l, Validation<e,b>>
public func *> <L, E: Semigroup, A, B>(
    _ lhs: Either<L, Validation<E, A>>,
    _ rhs: Either<L, Validation<E, B>>
) -> Either<L, Validation<E, B>> where L: Sendable, A: Sendable, B: Sendable {
    seqRightEitherValidation(lhs, rhs)
}

/// (<*) :: Either<l, Validation<e,a>> -> Either<l, Validation<e,b>> -> Either<l, Validation<e,a>>
public func <* <L, E: Semigroup, A, B>(
    _ lhs: Either<L, Validation<E, A>>,
    _ rhs: Either<L, Validation<E, B>>
) -> Either<L, Validation<E, A>> where L: Sendable, A: Sendable, B: Sendable {
    seqLeftEitherValidation(lhs, rhs)
}
