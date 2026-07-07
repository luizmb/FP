// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// EitherTNonEmpty: outer = Either, inner = NonEmpty
// Type: Either<L, NonEmpty<A>>

/// (<*>) :: Either<l, NonEmpty<(a -> b)>> -> Either<l, NonEmpty<a>> -> Either<l, NonEmpty<b>>
public func <*> <L, A, B>(
    _ eithF: Either<L, NonEmpty<@Sendable (A) -> B>>,
    _ eithA: Either<L, NonEmpty<A>>
) -> Either<L, NonEmpty<B>> {
    applyEitherNonEmpty(eithF, eithA)
}

/// (*>) :: Either<l, NonEmpty<a>> -> Either<l, NonEmpty<b>> -> Either<l, NonEmpty<b>>
public func *> <L, A, B>(
    _ lhs: Either<L, NonEmpty<A>>,
    _ rhs: Either<L, NonEmpty<B>>
) -> Either<L, NonEmpty<B>> where L: Sendable, A: Sendable, B: Sendable {
    seqRightEitherNonEmpty(lhs, rhs)
}

/// (<*) :: Either<l, NonEmpty<a>> -> Either<l, NonEmpty<b>> -> Either<l, NonEmpty<a>>
public func <* <L, A, B>(
    _ lhs: Either<L, NonEmpty<A>>,
    _ rhs: Either<L, NonEmpty<B>>
) -> Either<L, NonEmpty<A>> where L: Sendable, A: Sendable, B: Sendable {
    seqLeftEitherNonEmpty(lhs, rhs)
}
