import CoreFP

// ValidationTReader: outer = Validation, inner = Reader
// Type: Validation<E, Reader<Env, A>>
// Outer Validation accumulates errors; success case combines readers via Reader.apply.

public func applyValidationReader<E: Semigroup, Env, A, B>(
    _ vf: Validation<E, Reader<Env, (A) -> B>>,
    _ va: Validation<E, Reader<Env, A>>
) -> Validation<E, Reader<Env, B>> {
    Validation.liftA2(Reader.apply)(vf, va)
}

public func liftA2ValidationReader<E: Semigroup, Env, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Validation<E, Reader<Env, A>>, Validation<E, Reader<Env, B>>) -> Validation<E, Reader<Env, C>> {
    Validation.liftA2(Reader.liftA2(fn))
}

public func seqRightValidationReader<E: Semigroup, Env, A, B>(
    _ lhs: Validation<E, Reader<Env, A>>,
    _ rhs: Validation<E, Reader<Env, B>>
) -> Validation<E, Reader<Env, B>> {
    Validation.liftA2({ (ra: Reader<Env, A>, rb: Reader<Env, B>) in ra.seqRight(rb) })(lhs, rhs)
}

public func seqLeftValidationReader<E: Semigroup, Env, A, B>(
    _ lhs: Validation<E, Reader<Env, A>>,
    _ rhs: Validation<E, Reader<Env, B>>
) -> Validation<E, Reader<Env, A>> {
    Validation.liftA2({ (ra: Reader<Env, A>, rb: Reader<Env, B>) in ra.seqLeft(rb) })(lhs, rhs)
}
