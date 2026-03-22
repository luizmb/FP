import CoreFP

// ValidationTStateful: outer = Validation, inner = Stateful
// Type: Validation<E, Stateful<S, A>>
// Outer Validation accumulates errors; success case threads state via Stateful.apply.

public func applyValidationStateful<E: Semigroup, S, A, B>(
    _ vf: Validation<E, Stateful<S, (A) -> B>>,
    _ va: Validation<E, Stateful<S, A>>
) -> Validation<E, Stateful<S, B>> {
    Validation.liftA2(Stateful.apply)(vf, va)
}

public func liftA2ValidationStateful<E: Semigroup, S, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Validation<E, Stateful<S, A>>, Validation<E, Stateful<S, B>>) -> Validation<E, Stateful<S, C>> {
    Validation.liftA2(Stateful.liftA2(fn))
}

public func seqRightValidationStateful<E: Semigroup, S, A, B>(
    _ lhs: Validation<E, Stateful<S, A>>,
    _ rhs: Validation<E, Stateful<S, B>>
) -> Validation<E, Stateful<S, B>> {
    Validation.liftA2({ (sa: Stateful<S, A>, sb: Stateful<S, B>) in sa.seqRight(sb) })(lhs, rhs)
}

public func seqLeftValidationStateful<E: Semigroup, S, A, B>(
    _ lhs: Validation<E, Stateful<S, A>>,
    _ rhs: Validation<E, Stateful<S, B>>
) -> Validation<E, Stateful<S, A>> {
    Validation.liftA2({ (sa: Stateful<S, A>, sb: Stateful<S, B>) in sa.seqLeft(sb) })(lhs, rhs)
}
