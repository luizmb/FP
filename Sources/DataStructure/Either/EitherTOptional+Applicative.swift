// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?> = Either<L, Optional<A>>
// Haskell: MaybeT (Either L)
//
// The applicative is the one induced by the monad (`<*> = ap`), so it is sequential and
// short-circuits exactly like `flatMapTEitherOptional`: the first `.left` or `.right(nil)`
// in left-to-right order wins.

/// apply for EitherTOptional: Either<L,(A->B)?> -> Either<L,A?> -> Either<L,B?>
/// (<*>) = ap :: mf >>= \f -> fmap f ma
public func applyEitherOptional<L: Sendable, A: Sendable, B>(
    _ fns: Either<L, (@Sendable (A) -> B)?>,
    _ values: Either<L, A?>
) -> Either<L, B?> {
    flatMapTEitherOptional(fns) { fn in values.mapT(fn) }
}

/// liftA2 for EitherTOptional
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2EitherOptional<L: Sendable, A: Sendable, B: Sendable, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (Either<L, A?>, Either<L, B?>) -> Either<L, C?> {
    { lhs, rhs in flatMapTEitherOptional(lhs) { a in rhs.mapT { b in fn(a, b) } } }
}

/// seqRight for EitherTOptional
/// ma *> mb = ma >>= \_ -> mb
public func seqRightEitherOptional<L: Sendable, A, B: Sendable>(
    _ lhs: Either<L, A?>,
    _ rhs: Either<L, B?>
) -> Either<L, B?> {
    flatMapTEitherOptional(lhs, const(rhs))
}

/// seqLeft for EitherTOptional
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftEitherOptional<L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Either<L, A?>,
    _ rhs: Either<L, B?>
) -> Either<L, A?> {
    flatMapTEitherOptional(lhs) { a in rhs.mapT(const(a)) }
}
