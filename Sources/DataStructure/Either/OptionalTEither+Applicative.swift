// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>
// Haskell: ExceptT L Maybe
//
// The applicative is the one induced by the monad (`<*> = ap`), so it is sequential and
// short-circuits exactly like `flatMapT`: the first `nil` or `.some(.left)` in left-to-right
// order wins. Every function below is literally `flatMapT` + `mapT`.

/// apply for OptionalTEither: Either<L,(A->B)>? -> Either<L,A>? -> Either<L,B>?
/// (<*>) = ap :: mf >>= \f -> fmap f ma
public func applyOptionalEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fns: Either<L, @Sendable (A) -> B>?,
    _ values: Either<L, A>?
) -> Either<L, B>? {
    fns.flatMapT { fn in values.mapT(fn) }
}

/// liftA2 for OptionalTEither
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2OptionalEither<L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Either<L, A>?, Either<L, B>?) -> Either<L, C>? {
    { lhs, rhs in lhs.flatMapT { a in rhs.mapT { b in fn(a, b) } } }
}

/// seqRight for OptionalTEither
/// ma *> mb = ma >>= \_ -> mb
public func seqRightOptionalEither<L: Sendable, A: Sendable, B: Sendable>(_ lhs: Either<L, A>?, _ rhs: Either<L, B>?) -> Either<L, B>? {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for OptionalTEither
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftOptionalEither<L: Sendable, A: Sendable, B: Sendable>(_ lhs: Either<L, A>?, _ rhs: Either<L, B>?) -> Either<L, A>? {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
