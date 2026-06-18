// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<*>) :: Validation<e, Writer<w,(a->b)>> -> Validation<e, Writer<w,a>> -> Validation<e, Writer<w,b>>
public func <*> <E: Semigroup, W: Monoid, A, B>(
    _ fns: Validation<E, Writer<W, @Sendable (A) -> B>>,
    _ values: Validation<E, Writer<W, A>>
) -> Validation<E, Writer<W, B>> {
    applyValidationWriter(fns, values)
}

/// (*>) :: Validation<e, Writer<w,a>> -> Validation<e, Writer<w,b>> -> Validation<e, Writer<w,b>>
public func *> <E: Semigroup, W: Monoid, A, B>(
    _ lhs: Validation<E, Writer<W, A>>,
    _ rhs: Validation<E, Writer<W, B>>
) -> Validation<E, Writer<W, B>> {
    seqRightValidationWriter(lhs, rhs)
}

/// (<*) :: Validation<e, Writer<w,a>> -> Validation<e, Writer<w,b>> -> Validation<e, Writer<w,a>>
public func <* <E: Semigroup, W: Monoid, A, B>(
    _ lhs: Validation<E, Writer<W, A>>,
    _ rhs: Validation<E, Writer<W, B>>
) -> Validation<E, Writer<W, A>> {
    seqLeftValidationWriter(lhs, rhs)
}
