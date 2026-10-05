// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// NonEmptyTEither: outer = NonEmpty, inner = Either
// Type: NonEmpty<Either<L, A>>
// Haskell: ExceptT l NonEmpty
//
// The applicative is derived from the monad (`<*>` = `ap`): sequential and short-circuiting
// exactly like `flatMapT`. A `.left` on the left yields a single `.left` and never runs the right side.

/// apply for NonEmptyTEither: NonEmpty<Either<L, (A->B)>> -> NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>>
/// mf <*> ma = mf >>= \f -> fmap f ma
func applyNonEmptyEither<L: Sendable, A: Sendable, B>(
    _ fns: NonEmpty<Either<L, @Sendable (A) -> B>>,
    _ values: NonEmpty<Either<L, A>>
) -> NonEmpty<Either<L, B>> {
    fns.flatMapT { f in values.mapT(f) }
}

/// liftA2 for NonEmptyTEither: (A,B)->C -> NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>> -> NonEmpty<Either<L, C>>
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
func liftA2NonEmptyEither<L: Sendable, A: Sendable, B: Sendable, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (NonEmpty<Either<L, A>>, NonEmpty<Either<L, B>>) -> NonEmpty<Either<L, C>> {
    { neA, neB in
        neA.flatMapT { a in neB.mapT { b in fn(a, b) } }
    }
}

/// seqRight for NonEmptyTEither: NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>> -> NonEmpty<Either<L, B>>
/// ma *> mb = ma >>= \_ -> mb
func seqRightNonEmptyEither<L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: NonEmpty<Either<L, A>>,
    _ rhs: NonEmpty<Either<L, B>>
) -> NonEmpty<Either<L, B>> {
    lhs.flatMapT { (_: A) in rhs }
}

/// seqLeft for NonEmptyTEither: NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>> -> NonEmpty<Either<L, A>>
/// ma <* mb = ma >>= \a -> fmap (const a) mb
func seqLeftNonEmptyEither<L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: NonEmpty<Either<L, A>>,
    _ rhs: NonEmpty<Either<L, B>>
) -> NonEmpty<Either<L, A>> {
    lhs.flatMapT { a in rhs.mapT { (_: B) in a } }
}
