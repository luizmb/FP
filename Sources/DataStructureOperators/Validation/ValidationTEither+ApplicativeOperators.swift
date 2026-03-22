import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Validation<e, Either<l,(a->b)>> -> Validation<e, Either<l,a>> -> Validation<e, Either<l,b>>
public func <*> <E: Semigroup, L, A, B>(_ fns: Validation<E, Either<L, (A) -> B>>, _ values: Validation<E, Either<L, A>>) -> Validation<E, Either<L, B>> {
    applyValidationEither(fns, values)
}

// (*>) :: Validation<e, Either<l,a>> -> Validation<e, Either<l,b>> -> Validation<e, Either<l,b>>
public func *> <E: Semigroup, L, A, B>(_ lhs: Validation<E, Either<L, A>>, _ rhs: Validation<E, Either<L, B>>) -> Validation<E, Either<L, B>> {
    seqRightValidationEither(lhs, rhs)
}

// (<*) :: Validation<e, Either<l,a>> -> Validation<e, Either<l,b>> -> Validation<e, Either<l,a>>
public func <* <E: Semigroup, L, A, B>(_ lhs: Validation<E, Either<L, A>>, _ rhs: Validation<E, Either<L, B>>) -> Validation<E, Either<L, A>> {
    seqLeftValidationEither(lhs, rhs)
}
