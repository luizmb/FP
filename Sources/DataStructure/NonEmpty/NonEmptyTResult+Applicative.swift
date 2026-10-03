// SPDX-License-Identifier: Apache-2.0
// NonEmptyTResult: outer = NonEmpty, inner = Result
// Type: NonEmpty<Result<A, E>>  (Success = A, Failure = E)
// Haskell: ExceptT e NonEmpty
//
// The applicative is derived from the monad (`<*>` = `ap`): sequential and short-circuiting
// exactly like `flatMapT`. A `.failure` on the left yields a single `.failure` and never runs the right side.

/// apply for NonEmptyTResult: NonEmpty<Result<(A->B),E>> -> NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>>
/// mf <*> ma = mf >>= \f -> fmap f ma
public func applyNonEmptyResult<A, B, E>(
    _ fns: NonEmpty<Result<@Sendable (A) -> B, E>>,
    _ values: NonEmpty<Result<A, E>>
) -> NonEmpty<Result<B, E>> {
    fns.flatMapT { f in values.mapT(f) }
}

/// liftA2 for NonEmptyTResult: (A,B)->C -> NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>> -> NonEmpty<Result<C,E>>
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2NonEmptyResult<A, B, C, E>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (NonEmpty<Result<A, E>>, NonEmpty<Result<B, E>>) -> NonEmpty<Result<C, E>> {
    { neA, neB in
        neA.flatMapT { a in neB.mapT { b in fn(a, b) } }
    }
}

/// seqRight for NonEmptyTResult: NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>> -> NonEmpty<Result<B,E>>
/// ma *> mb = ma >>= \_ -> mb
public func seqRightNonEmptyResult<A, B, E>(
    _ lhs: NonEmpty<Result<A, E>>,
    _ rhs: NonEmpty<Result<B, E>>
) -> NonEmpty<Result<B, E>> {
    lhs.flatMapT { (_: A) in rhs }
}

/// seqLeft for NonEmptyTResult: NonEmpty<Result<A,E>> -> NonEmpty<Result<B,E>> -> NonEmpty<Result<A,E>>
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftNonEmptyResult<A, B, E>(
    _ lhs: NonEmpty<Result<A, E>>,
    _ rhs: NonEmpty<Result<B, E>>
) -> NonEmpty<Result<A, E>> {
    lhs.flatMapT { a in rhs.mapT { (_: B) in a } }
}
