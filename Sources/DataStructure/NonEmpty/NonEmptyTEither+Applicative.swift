// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// NonEmptyTEither: outer = NonEmpty, inner = Either
// Type: NonEmpty<Either<L, A>>

/// apply for NonEmptyTEither: NonEmpty<Either<L, (A->B)>> -> NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>>
/// Cartesian product with Either apply at each pair
public func applyNonEmptyEither<L: Sendable, A: Sendable, B>(
    _ fns: NonEmpty<Either<L, @Sendable (A) -> B>>,
    _ values: NonEmpty<Either<L, A>>
) -> NonEmpty<Either<L, B>> {
    NonEmpty.liftA2 { @Sendable f, a in Either.apply(f, a) }(fns, values)
}

/// liftA2 for NonEmptyTEither: (A,B)->C -> NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>> -> NonEmpty<Either<L, C>>
public func liftA2NonEmptyEither<L: Sendable, A: Sendable, B: Sendable, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (NonEmpty<Either<L, A>>, NonEmpty<Either<L, B>>) -> NonEmpty<Either<L, C>> {
    { neA, neB in
        NonEmpty.liftA2 { @Sendable ea, eb in Either.liftA2(fn)(ea, eb) }(neA, neB)
    }
}

/// seqRight for NonEmptyTEither: NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>> -> NonEmpty<Either<L, B>>
public func seqRightNonEmptyEither<L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: NonEmpty<Either<L, A>>,
    _ rhs: NonEmpty<Either<L, B>>
) -> NonEmpty<Either<L, B>> {
    NonEmpty.liftA2 { (a: Either<L, A>, b: Either<L, B>) in a.seqRight(b) }(lhs, rhs)
}

/// seqLeft for NonEmptyTEither: NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>> -> NonEmpty<Either<L, A>>
public func seqLeftNonEmptyEither<L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: NonEmpty<Either<L, A>>,
    _ rhs: NonEmpty<Either<L, B>>
) -> NonEmpty<Either<L, A>> {
    NonEmpty.liftA2 { (a: Either<L, A>, b: Either<L, B>) in a.seqLeft(b) }(lhs, rhs)
}
