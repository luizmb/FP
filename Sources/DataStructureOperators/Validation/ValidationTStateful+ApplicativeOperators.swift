import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Validation<e, Stateful<s,(a->b)>> -> Validation<e, Stateful<s,a>> -> Validation<e, Stateful<s,b>>
public func <*> <E: Semigroup, S, A, B>(
    _ fns: Validation<E, Stateful<S, (A) -> B>>,
    _ values: Validation<E, Stateful<S, A>>
) -> Validation<E, Stateful<S, B>> {
    applyValidationStateful(fns, values)
}

// (*>) :: Validation<e, Stateful<s,a>> -> Validation<e, Stateful<s,b>> -> Validation<e, Stateful<s,b>>
public func *> <E: Semigroup, S, A, B>(
    _ lhs: Validation<E, Stateful<S, A>>,
    _ rhs: Validation<E, Stateful<S, B>>
) -> Validation<E, Stateful<S, B>> {
    seqRightValidationStateful(lhs, rhs)
}

// (<*) :: Validation<e, Stateful<s,a>> -> Validation<e, Stateful<s,b>> -> Validation<e, Stateful<s,a>>
public func <* <E: Semigroup, S, A, B>(
    _ lhs: Validation<E, Stateful<S, A>>,
    _ rhs: Validation<E, Stateful<S, B>>
) -> Validation<E, Stateful<S, A>> {
    seqLeftValidationStateful(lhs, rhs)
}
