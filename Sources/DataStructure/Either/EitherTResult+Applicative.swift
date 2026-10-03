// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A, E>>
// Haskell: ExceptT E (Either L)
//
// The applicative is the one induced by the monad (`<*> = ap`), so it is sequential and
// short-circuits exactly like `flatMapTEitherResult`: the first `.left` or `.right(.failure)`
// in left-to-right order wins. Each function below is `flatMapTEitherResult` + `mapTEitherResult`
// with the bind's case analysis inlined, so no non-`Sendable` value is captured in a `@Sendable` closure.

/// apply for EitherTResult: Either<L, Result<(A->B), E>> -> Either<L, Result<A, E>> -> Either<L, Result<B, E>>
/// (<*>) = ap :: mf >>= \f -> fmap f ma
public func applyEitherResult<L, A, B, E: Error>(
    _ fns: Either<L, Result<@Sendable (A) -> B, E>>,
    _ values: Either<L, Result<A, E>>
) -> Either<L, Result<B, E>> {
    switch fns {
    case let .left(l):
        .left(l)

    case let .right(.failure(e)):
        .right(.failure(e))

    case let .right(.success(fn)):
        mapTEitherResult(fn, values)
    }
}

/// liftA2 for EitherTResult
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2EitherResult<L, A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Either<L, Result<A, E>>, Either<L, Result<B, E>>) -> Either<L, Result<C, E>> {
    { lhs, rhs in
        switch (lhs, rhs) {
        case let (.left(l), _):
            .left(l)

        case let (.right(.failure(e)), _):
            .right(.failure(e))

        case let (.right(.success), .left(l)):
            .left(l)

        case let (.right(.success(a)), .right(resultB)):
            .right(resultB.map { b in fn(a, b) })
        }
    }
}

/// seqRight for EitherTResult
/// ma *> mb = ma >>= \_ -> mb
public func seqRightEitherResult<L, A, B, E: Error>(
    _ lhs: Either<L, Result<A, E>>,
    _ rhs: Either<L, Result<B, E>>
) -> Either<L, Result<B, E>> {
    switch lhs {
    case let .left(l):
        .left(l)

    case let .right(.failure(e)):
        .right(.failure(e))

    case .right(.success):
        rhs
    }
}

/// seqLeft for EitherTResult
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftEitherResult<L, A, B, E: Error>(
    _ lhs: Either<L, Result<A, E>>,
    _ rhs: Either<L, Result<B, E>>
) -> Either<L, Result<A, E>> {
    switch (lhs, rhs) {
    case let (.left(l), _):
        .left(l)

    case let (.right(.failure(e)), _):
        .right(.failure(e))

    case let (.right(.success), .left(l)):
        .left(l)

    case let (.right(.success(a)), .right(resultB)):
        .right(resultB.map(const(a)))
    }
}
