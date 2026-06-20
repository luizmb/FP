// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTOptional: outer = Validation, inner = Optional
// Type: Validation<E, A?>

/// apply for Validation<E, (A->B)?> -> Validation<E, A?> -> Validation<E, B?>
/// Outer Validation accumulates errors; inner Optional applies normally.
public func applyValidationOptional<E: Semigroup, A, B>(
    _ vf: Validation<E, (@Sendable (A) -> B)?>,
    _ va: Validation<E, A?>
) -> Validation<E, B?> {
    Validation.liftA2(Optional.apply)(vf, va)
}

/// `liftA2ValidationOptional`.
public func liftA2ValidationOptional<E: Semigroup, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Validation<E, A?>, Validation<E, B?>) -> Validation<E, C?> {
    Validation.liftA2(Optional.liftA2(fn))
}

/// `seqRightValidationOptional`.
public func seqRightValidationOptional<E: Semigroup, A, B>(
    _ lhs: Validation<E, A?>,
    _ rhs: Validation<E, B?>
) -> Validation<E, B?> {
    Validation.liftA2 { (a: A?, b: B?) in a.seqRight(b) }(lhs, rhs)
}

/// `seqLeftValidationOptional`.
public func seqLeftValidationOptional<E: Semigroup, A, B>(
    _ lhs: Validation<E, A?>,
    _ rhs: Validation<E, B?>
) -> Validation<E, A?> {
    Validation.liftA2 { (a: A?, b: B?) in a.seqLeft(b) }(lhs, rhs)
}
