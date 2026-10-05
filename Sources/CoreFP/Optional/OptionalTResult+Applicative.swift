// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTResult: outer = Optional, inner = Result
// Type: Result<A,E>? = Optional<Result<A,E>>
// Haskell: ExceptT E Maybe
//
// The applicative is the one induced by the monad (`<*> = ap`), so it is sequential and
// short-circuits exactly like `flatMapT`: the first `nil` or `.some(.failure)` in left-to-right
// order wins.

/// apply for OptionalTResult: Result<(A->B),E>? -> Result<A,E>? -> Result<B,E>?
/// (<*>) = ap :: mf >>= \f -> fmap f ma
func applyOptionalResult<A: Sendable, B, E: Error>(
    _ fns: Result<@Sendable (A) -> B, E>?,
    _ values: Result<A, E>?
) -> Result<B, E>? {
    fns.flatMapT { fn in values.mapT(fn) }
}

/// liftA2 for OptionalTResult
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
func liftA2OptionalResult<A: Sendable, B: Sendable, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (Result<A, E>?, Result<B, E>?) -> Result<C, E>? {
    { lhs, rhs in lhs.flatMapT { a in rhs.mapT { b in fn(a, b) } } }
}

/// seqRight for OptionalTResult
/// ma *> mb = ma >>= \_ -> mb
func seqRightOptionalResult<A, B: Sendable, E: Error>(_ lhs: Result<A, E>?, _ rhs: Result<B, E>?) -> Result<B, E>? {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for OptionalTResult
/// ma <* mb = ma >>= \a -> fmap (const a) mb
func seqLeftOptionalResult<A: Sendable, B: Sendable, E: Error>(_ lhs: Result<A, E>?, _ rhs: Result<B, E>?) -> Result<A, E>? {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
