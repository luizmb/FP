import CoreFP
import DataStructure
import CoreFPOperators

// (<*>) :: Validation<e, Result<(a->b), err>> -> Validation<e, Result<a, err>> -> Validation<e, Result<b, err>>
public func <*> <E: Semigroup, A, B, Err: Error>(
    _ fns: Validation<E, Result<(A) -> B, Err>>,
    _ values: Validation<E, Result<A, Err>>
) -> Validation<E, Result<B, Err>> {
    applyValidationResult(fns, values)
}

// (*>) :: Validation<e, Result<a, err>> -> Validation<e, Result<b, err>> -> Validation<e, Result<b, err>>
public func *> <E: Semigroup, A, B, Err: Error>(
    _ lhs: Validation<E, Result<A, Err>>,
    _ rhs: Validation<E, Result<B, Err>>
) -> Validation<E, Result<B, Err>> {
    seqRightValidationResult(lhs, rhs)
}

// (<*) :: Validation<e, Result<a, err>> -> Validation<e, Result<b, err>> -> Validation<e, Result<a, err>>
public func <* <E: Semigroup, A, B, Err: Error>(
    _ lhs: Validation<E, Result<A, Err>>,
    _ rhs: Validation<E, Result<B, Err>>
) -> Validation<E, Result<A, Err>> {
    seqLeftValidationResult(lhs, rhs)
}
