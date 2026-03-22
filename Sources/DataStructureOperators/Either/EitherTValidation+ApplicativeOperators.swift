import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Either<l, Validation<e,(a->b)>> -> Either<l, Validation<e,a>> -> Either<l, Validation<e,b>>
public func <*> <L, E: Semigroup, A, B>(_ fns: Either<L, Validation<E, (A) -> B>>, _ values: Either<L, Validation<E, A>>) -> Either<L, Validation<E, B>> {
    applyEitherValidation(fns, values)
}

// (*>) :: Either<l, Validation<e,a>> -> Either<l, Validation<e,b>> -> Either<l, Validation<e,b>>
public func *> <L, E: Semigroup, A, B>(_ lhs: Either<L, Validation<E, A>>, _ rhs: Either<L, Validation<E, B>>) -> Either<L, Validation<E, B>> {
    seqRightEitherValidation(lhs, rhs)
}

// (<*) :: Either<l, Validation<e,a>> -> Either<l, Validation<e,b>> -> Either<l, Validation<e,a>>
public func <* <L, E: Semigroup, A, B>(_ lhs: Either<L, Validation<E, A>>, _ rhs: Either<L, Validation<E, B>>) -> Either<L, Validation<E, A>> {
    seqLeftEitherValidation(lhs, rhs)
}
