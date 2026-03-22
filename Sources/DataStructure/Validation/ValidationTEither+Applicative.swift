import CoreFP

// ValidationTEither: outer = Validation, inner = Either
// Type: Validation<E, Either<L, A>>
// Outer Validation accumulates errors; inner Either short-circuits on its own left.

public func applyValidationEither<E: Semigroup, L, A, B>(
    _ vf: Validation<E, Either<L, (A) -> B>>,
    _ va: Validation<E, Either<L, A>>
) -> Validation<E, Either<L, B>> {
    Validation.liftA2(Either.apply)(vf, va)
}

public func liftA2ValidationEither<E: Semigroup, L, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Validation<E, Either<L, A>>, Validation<E, Either<L, B>>) -> Validation<E, Either<L, C>> {
    Validation.liftA2(Either.liftA2(fn))
}

public func seqRightValidationEither<E: Semigroup, L, A, B>(
    _ lhs: Validation<E, Either<L, A>>,
    _ rhs: Validation<E, Either<L, B>>
) -> Validation<E, Either<L, B>> {
    Validation.liftA2({ (a: Either<L, A>, b: Either<L, B>) in a.seqRight(b) })(lhs, rhs)
}

public func seqLeftValidationEither<E: Semigroup, L, A, B>(
    _ lhs: Validation<E, Either<L, A>>,
    _ rhs: Validation<E, Either<L, B>>
) -> Validation<E, Either<L, A>> {
    Validation.liftA2({ (a: Either<L, A>, b: Either<L, B>) in a.seqLeft(b) })(lhs, rhs)
}
