// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A, E>>
// Haskell: ExceptT E (Either L)
//
// The applicative is the one induced by the monad (`<*> = ap`), so it is sequential and
// short-circuits exactly like `flatMapTEitherResult`: the first `.left` or `.right(.failure)`
// in left-to-right order wins.

/// apply for EitherTResult: Either<L, Result<(A->B), E>> -> Either<L, Result<A, E>> -> Either<L, Result<B, E>>
/// (<*>) = ap :: mf >>= \f -> fmap f ma
public func applyEitherResult<L: Sendable, A: Sendable, B, E: Error>(
    _ fns: Either<L, Result<@Sendable (A) -> B, E>>,
    _ values: Either<L, Result<A, E>>
) -> Either<L, Result<B, E>> {
    flatMapTEitherResult(fns) { fn in values.mapT(fn) }
}

/// liftA2 for EitherTResult
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2EitherResult<L: Sendable, A: Sendable, B: Sendable, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (Either<L, Result<A, E>>, Either<L, Result<B, E>>) -> Either<L, Result<C, E>> {
    { lhs, rhs in flatMapTEitherResult(lhs) { a in rhs.mapT { b in fn(a, b) } } }
}

/// seqRight for EitherTResult
/// ma *> mb = ma >>= \_ -> mb
public func seqRightEitherResult<L: Sendable, A, B: Sendable, E: Error>(
    _ lhs: Either<L, Result<A, E>>,
    _ rhs: Either<L, Result<B, E>>
) -> Either<L, Result<B, E>> {
    flatMapTEitherResult(lhs, const(rhs))
}

/// seqLeft for EitherTResult
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftEitherResult<L: Sendable, A: Sendable, B: Sendable, E: Error>(
    _ lhs: Either<L, Result<A, E>>,
    _ rhs: Either<L, Result<B, E>>
) -> Either<L, Result<A, E>> {
    flatMapTEitherResult(lhs) { a in rhs.mapT(const(a)) }
}
