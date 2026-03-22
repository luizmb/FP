import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Validation<e, (a->b)?> -> Validation<e, a?> -> Validation<e, b?>
public func <*> <E: Semigroup, A, B>(_ fns: Validation<E, ((A) -> B)?>, _ values: Validation<E, A?>) -> Validation<E, B?> {
    applyValidationOptional(fns, values)
}

// (*>) :: Validation<e, a?> -> Validation<e, b?> -> Validation<e, b?>
public func *> <E: Semigroup, A, B>(_ lhs: Validation<E, A?>, _ rhs: Validation<E, B?>) -> Validation<E, B?> {
    seqRightValidationOptional(lhs, rhs)
}

// (<*) :: Validation<e, a?> -> Validation<e, b?> -> Validation<e, a?>
public func <* <E: Semigroup, A, B>(_ lhs: Validation<E, A?>, _ rhs: Validation<E, B?>) -> Validation<E, A?> {
    seqLeftValidationOptional(lhs, rhs)
}
