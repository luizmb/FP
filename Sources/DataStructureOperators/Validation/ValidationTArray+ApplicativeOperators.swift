import CoreFP
import DataStructure
import CoreFPOperators

// (<*>) :: Validation<e, [(a->b)]> -> Validation<e, [a]> -> Validation<e, [b]>
public func <*> <E: Semigroup, A, B>(_ fns: Validation<E, [(A) -> B]>, _ values: Validation<E, [A]>) -> Validation<E, [B]> {
    applyValidationArray(fns, values)
}

// (*>) :: Validation<e, [a]> -> Validation<e, [b]> -> Validation<e, [b]>
public func *> <E: Semigroup, A, B>(_ lhs: Validation<E, [A]>, _ rhs: Validation<E, [B]>) -> Validation<E, [B]> {
    seqRightValidationArray(lhs, rhs)
}

// (<*) :: Validation<e, [a]> -> Validation<e, [b]> -> Validation<e, [a]>
public func <* <E: Semigroup, A, B>(_ lhs: Validation<E, [A]>, _ rhs: Validation<E, [B]>) -> Validation<E, [A]> {
    seqLeftValidationArray(lhs, rhs)
}
