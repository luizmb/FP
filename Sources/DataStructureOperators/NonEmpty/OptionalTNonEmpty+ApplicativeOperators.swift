// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// OptionalTNonEmpty: outer = Optional, inner = NonEmpty
// Type: NonEmpty<A>? = Optional<NonEmpty<A>>

/// (<*>) :: NonEmpty<(A->B)>? -> NonEmpty<A>? -> NonEmpty<B>?
public func <*> <A: Sendable, B: Sendable>(_ fns: NonEmpty<@Sendable (A) -> B>?, _ values: NonEmpty<A>?) -> NonEmpty<B>? {
    applyOptionalNonEmpty(fns, values)
}

/// (*>) :: NonEmpty<A>? -> NonEmpty<B>? -> NonEmpty<B>?
public func *> <A, B>(_ lhs: NonEmpty<A>?, _ rhs: NonEmpty<B>?) -> NonEmpty<B>? {
    seqRightOptionalNonEmpty(lhs, rhs)
}

/// (<*) :: NonEmpty<A>? -> NonEmpty<B>? -> NonEmpty<A>?
public func <* <A, B>(_ lhs: NonEmpty<A>?, _ rhs: NonEmpty<B>?) -> NonEmpty<A>? {
    seqLeftOptionalNonEmpty(lhs, rhs)
}
