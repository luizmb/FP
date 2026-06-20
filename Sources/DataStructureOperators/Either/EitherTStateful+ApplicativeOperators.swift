// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (<*>) :: Either<l, Stateful<s, (a -> b)>> -> Either<l, Stateful<s, a>> -> Either<l, Stateful<s, b>>
public func <*> <L, S, A, B>(
    _ eithF: Either<L, Stateful<S, @Sendable (A) -> B>>,
    _ eithA: Either<L, Stateful<S, A>>
) -> Either<L, Stateful<S, B>> {
    applyEitherStateful(eithF, eithA)
}

/// (*>) :: Either<l, Stateful<s, a>> -> Either<l, Stateful<s, b>> -> Either<l, Stateful<s, b>>
public func *> <L, S, A, B>(
    _ lhs: Either<L, Stateful<S, A>>,
    _ rhs: Either<L, Stateful<S, B>>
) -> Either<L, Stateful<S, B>> where L: Sendable, S: Sendable, A: Sendable, B: Sendable {
    seqRightEitherStateful(lhs, rhs)
}

/// (<*) :: Either<l, Stateful<s, a>> -> Either<l, Stateful<s, b>> -> Either<l, Stateful<s, a>>
public func <* <L, S, A, B>(
    _ lhs: Either<L, Stateful<S, A>>,
    _ rhs: Either<L, Stateful<S, B>>
) -> Either<L, Stateful<S, A>> where L: Sendable, S: Sendable, A: Sendable, B: Sendable {
    seqLeftEitherStateful(lhs, rhs)
}
