// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// EitherTValidation: outer = Either, inner = Validation
/// Type: Either<L, Validation<E, A>>
/// Outer Either short-circuits on left; inner Validation accumulates errors.

public func applyEitherValidation<L, E: Semigroup, A, B>(
    _ eitherF: Either<L, Validation<E, @Sendable (A) -> B>>,
    _ eitherA: Either<L, Validation<E, A>>
) -> Either<L, Validation<E, B>> {
    Either.liftA2(Validation.apply)(eitherF, eitherA)
}

/// `liftA2EitherValidation`.
public func liftA2EitherValidation<L, E: Semigroup, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Either<L, Validation<E, A>>, Either<L, Validation<E, B>>) -> Either<L, Validation<E, C>> {
    Either.liftA2(Validation.liftA2(fn))
}

/// `seqRightEitherValidation`.
public func seqRightEitherValidation<L, E: Semigroup, A, B>(
    _ lhs: Either<L, Validation<E, A>>,
    _ rhs: Either<L, Validation<E, B>>
) -> Either<L, Validation<E, B>> {
    Either.liftA2({ (va: Validation<E, A>, vb: Validation<E, B>) in va.seqRight(vb) })(lhs, rhs)
}

/// `seqLeftEitherValidation`.
public func seqLeftEitherValidation<L, E: Semigroup, A, B>(
    _ lhs: Either<L, Validation<E, A>>,
    _ rhs: Either<L, Validation<E, B>>
) -> Either<L, Validation<E, A>> {
    Either.liftA2({ (va: Validation<E, A>, vb: Validation<E, B>) in va.seqLeft(vb) })(lhs, rhs)
}
