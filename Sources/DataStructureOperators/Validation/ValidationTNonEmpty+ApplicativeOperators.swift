// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<*>) :: Validation<e, NonEmpty<(a->b)>> -> Validation<e, NonEmpty<a>> -> Validation<e, NonEmpty<b>>
public func <*> <E: Semigroup, A, B>(
    _ fns: Validation<E, NonEmpty<@Sendable (A) -> B>>,
    _ values: Validation<E, NonEmpty<A>>
) -> Validation<E, NonEmpty<B>> {
    applyValidationNonEmpty(fns, values)
}

/// (*>) :: Validation<e, NonEmpty<a>> -> Validation<e, NonEmpty<b>> -> Validation<e, NonEmpty<b>>
public func *> <E: Semigroup, A, B>(
    _ lhs: Validation<E, NonEmpty<A>>,
    _ rhs: Validation<E, NonEmpty<B>>
) -> Validation<E, NonEmpty<B>> {
    seqRightValidationNonEmpty(lhs, rhs)
}

/// (<*) :: Validation<e, NonEmpty<a>> -> Validation<e, NonEmpty<b>> -> Validation<e, NonEmpty<a>>
public func <* <E: Semigroup, A, B>(
    _ lhs: Validation<E, NonEmpty<A>>,
    _ rhs: Validation<E, NonEmpty<B>>
) -> Validation<E, NonEmpty<A>> {
    seqLeftValidationNonEmpty(lhs, rhs)
}
