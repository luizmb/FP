// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// ValidationTNonEmpty: outer = Validation, inner = NonEmpty
/// Type: Validation<E, NonEmpty<A>>

public func applyValidationNonEmpty<E: Semigroup, A, B>(
    _ fns: Validation<E, NonEmpty<@Sendable (A) -> B>>,
    _ values: Validation<E, NonEmpty<A>>
) -> Validation<E, NonEmpty<B>> {
    Validation.liftA2(NonEmpty.apply)(fns, values)
}

/// `liftA2ValidationNonEmpty`.
public func liftA2ValidationNonEmpty<E: Semigroup, A: Sendable, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Validation<E, NonEmpty<A>>, Validation<E, NonEmpty<B>>) -> Validation<E, NonEmpty<C>> {
    Validation.liftA2(NonEmpty.liftA2(fn))
}

/// `seqRightValidationNonEmpty`.
public func seqRightValidationNonEmpty<E: Semigroup, A, B>(
    _ lhs: Validation<E, NonEmpty<A>>,
    _ rhs: Validation<E, NonEmpty<B>>
) -> Validation<E, NonEmpty<B>> {
    Validation.liftA2 { (a: NonEmpty<A>, b: NonEmpty<B>) in a.seqRight(b) }(lhs, rhs)
}

/// `seqLeftValidationNonEmpty`.
public func seqLeftValidationNonEmpty<E: Semigroup, A, B>(
    _ lhs: Validation<E, NonEmpty<A>>,
    _ rhs: Validation<E, NonEmpty<B>>
) -> Validation<E, NonEmpty<A>> {
    Validation.liftA2 { (a: NonEmpty<A>, b: NonEmpty<B>) in a.seqLeft(b) }(lhs, rhs)
}
