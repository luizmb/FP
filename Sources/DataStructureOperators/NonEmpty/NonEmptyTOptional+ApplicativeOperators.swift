// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?> = NonEmpty<Optional<A>>

/// (<*>) :: NonEmpty<(A->B)?> -> NonEmpty<A?> -> NonEmpty<B?>
public func <*> <A: Sendable, B: Sendable>(
    _ fns: NonEmpty<(@Sendable (A) -> B)?>,
    _ values: NonEmpty<A?>
) -> NonEmpty<B?> {
    applyNonEmptyOptional(fns, values)
}

/// (*>) :: NonEmpty<A?> -> NonEmpty<B?> -> NonEmpty<B?>
public func *> <A: Sendable, B: Sendable>(_ lhs: NonEmpty<A?>, _ rhs: NonEmpty<B?>) -> NonEmpty<B?> {
    seqRightNonEmptyOptional(lhs, rhs)
}

/// (<*) :: NonEmpty<A?> -> NonEmpty<B?> -> NonEmpty<A?>
public func <* <A: Sendable, B: Sendable>(_ lhs: NonEmpty<A?>, _ rhs: NonEmpty<B?>) -> NonEmpty<A?> {
    seqLeftNonEmptyOptional(lhs, rhs)
}
