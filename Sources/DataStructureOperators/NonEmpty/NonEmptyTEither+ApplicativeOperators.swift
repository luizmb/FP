// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// NonEmptyTEither: outer = NonEmpty, inner = Either
// Type: NonEmpty<Either<L, A>>

/// (<*>) :: NonEmpty<Either<L, (A -> B)>> -> NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>>
public func <*> <L: Sendable, A: Sendable, B>(
    _ fns: NonEmpty<Either<L, @Sendable (A) -> B>>,
    _ values: NonEmpty<Either<L, A>>
) -> NonEmpty<Either<L, B>> {
    applyNonEmptyEither(fns, values)
}

/// (*>) :: NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>> -> NonEmpty<Either<L, B>>
public func *> <L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: NonEmpty<Either<L, A>>,
    _ rhs: NonEmpty<Either<L, B>>
) -> NonEmpty<Either<L, B>> {
    seqRightNonEmptyEither(lhs, rhs)
}

/// (<*) :: NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>> -> NonEmpty<Either<L, A>>
public func <* <L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: NonEmpty<Either<L, A>>,
    _ rhs: NonEmpty<Either<L, B>>
) -> NonEmpty<Either<L, A>> {
    seqLeftNonEmptyEither(lhs, rhs)
}
