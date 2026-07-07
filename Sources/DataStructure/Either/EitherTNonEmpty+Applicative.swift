// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// EitherTNonEmpty: outer = Either, inner = NonEmpty
// Type: Either<L, NonEmpty<A>>

/// apply for EitherTNonEmpty: Either<L,NonEmpty<(A->B)>> -> Either<L,NonEmpty<A>> -> Either<L,NonEmpty<B>>
public func applyEitherNonEmpty<L, A, B>(
    _ eithF: Either<L, NonEmpty<@Sendable (A) -> B>>,
    _ eithA: Either<L, NonEmpty<A>>
) -> Either<L, NonEmpty<B>> {
    Either.liftA2 { nf, na in NonEmpty.apply(nf, na) }(eithF, eithA)
}

/// liftA2 for EitherTNonEmpty
public func liftA2EitherNonEmpty<L, A: Sendable, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Either<L, NonEmpty<A>>, Either<L, NonEmpty<B>>) -> Either<L, NonEmpty<C>> {
    { ea, eb in
        Either.liftA2 { na, nb in NonEmpty.liftA2(fn)(na, nb) }(ea, eb)
    }
}

/// seqRight for EitherTNonEmpty
public func seqRightEitherNonEmpty<L, A, B>(
    _ lhs: Either<L, NonEmpty<A>>,
    _ rhs: Either<L, NonEmpty<B>>
) -> Either<L, NonEmpty<B>> {
    Either.liftA2 { (na: NonEmpty<A>, nb: NonEmpty<B>) in na.seqRight(nb) }(lhs, rhs)
}

/// seqLeft for EitherTNonEmpty
public func seqLeftEitherNonEmpty<L, A, B>(
    _ lhs: Either<L, NonEmpty<A>>,
    _ rhs: Either<L, NonEmpty<B>>
) -> Either<L, NonEmpty<A>> {
    Either.liftA2 { (na: NonEmpty<A>, nb: NonEmpty<B>) in na.seqLeft(nb) }(lhs, rhs)
}
