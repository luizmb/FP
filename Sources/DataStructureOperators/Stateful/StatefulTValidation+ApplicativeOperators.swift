import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Stateful<s, Validation<e,(a->b)>> -> Stateful<s, Validation<e,a>> -> Stateful<s, Validation<e,b>>
public func <*> <S, E: Semigroup, A, B>(
    _ sf: Stateful<S, Validation<E, (A) -> B>>,
    _ sa: Stateful<S, Validation<E, A>>
) -> Stateful<S, Validation<E, B>> {
    applyStatefulValidation(sf, sa)
}

// (*>) :: Stateful<s, Validation<e,a>> -> Stateful<s, Validation<e,b>> -> Stateful<s, Validation<e,b>>
public func *> <S, E: Semigroup, A, B>(
    _ lhs: Stateful<S, Validation<E, A>>,
    _ rhs: Stateful<S, Validation<E, B>>
) -> Stateful<S, Validation<E, B>> {
    seqRightStatefulValidation(lhs, rhs)
}

// (<*) :: Stateful<s, Validation<e,a>> -> Stateful<s, Validation<e,b>> -> Stateful<s, Validation<e,a>>
public func <* <S, E: Semigroup, A, B>(
    _ lhs: Stateful<S, Validation<E, A>>,
    _ rhs: Stateful<S, Validation<E, B>>
) -> Stateful<S, Validation<E, A>> {
    seqLeftStatefulValidation(lhs, rhs)
}
