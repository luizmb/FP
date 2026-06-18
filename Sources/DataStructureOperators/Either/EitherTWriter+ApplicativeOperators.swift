// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<*>) :: Either<l, Writer<w, (a -> b)>> -> Either<l, Writer<w, a>> -> Either<l, Writer<w, b>>
public func <*> <L, W: Monoid, A, B>(
    _ eithF: Either<L, Writer<W, @Sendable (A) -> B>>,
    _ eithA: Either<L, Writer<W, A>>
) -> Either<L, Writer<W, B>> {
    applyEitherWriter(eithF, eithA)
}

/// (*>) :: Either<l, Writer<w, a>> -> Either<l, Writer<w, b>> -> Either<l, Writer<w, b>>
public func *> <L, W: Monoid, A, B>(
    _ lhs: Either<L, Writer<W, A>>,
    _ rhs: Either<L, Writer<W, B>>
) -> Either<L, Writer<W, B>> where L: Sendable, A: Sendable, B: Sendable {
    seqRightEitherWriter(lhs, rhs)
}

/// (<*) :: Either<l, Writer<w, a>> -> Either<l, Writer<w, b>> -> Either<l, Writer<w, a>>
public func <* <L, W: Monoid, A, B>(
    _ lhs: Either<L, Writer<W, A>>,
    _ rhs: Either<L, Writer<W, B>>
) -> Either<L, Writer<W, A>> where L: Sendable, A: Sendable, B: Sendable {
    seqLeftEitherWriter(lhs, rhs)
}
