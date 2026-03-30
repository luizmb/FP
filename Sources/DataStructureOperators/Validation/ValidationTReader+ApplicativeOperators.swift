import CoreFP
import DataStructure
import CoreFPOperators

// (<*>) :: Validation<e, Reader<env,(a->b)>> -> Validation<e, Reader<env,a>> -> Validation<e, Reader<env,b>>
public func <*> <E: Semigroup, Env, A, B>(
    _ fns: Validation<E, Reader<Env, (A) -> B>>,
    _ values: Validation<E, Reader<Env, A>>
) -> Validation<E, Reader<Env, B>> {
    applyValidationReader(fns, values)
}

// (*>) :: Validation<e, Reader<env,a>> -> Validation<e, Reader<env,b>> -> Validation<e, Reader<env,b>>
public func *> <E: Semigroup, Env, A, B>(
    _ lhs: Validation<E, Reader<Env, A>>,
    _ rhs: Validation<E, Reader<Env, B>>
) -> Validation<E, Reader<Env, B>> {
    seqRightValidationReader(lhs, rhs)
}

// (<*) :: Validation<e, Reader<env,a>> -> Validation<e, Reader<env,b>> -> Validation<e, Reader<env,a>>
public func <* <E: Semigroup, Env, A, B>(
    _ lhs: Validation<E, Reader<Env, A>>,
    _ rhs: Validation<E, Reader<Env, B>>
) -> Validation<E, Reader<Env, A>> {
    seqLeftValidationReader(lhs, rhs)
}
