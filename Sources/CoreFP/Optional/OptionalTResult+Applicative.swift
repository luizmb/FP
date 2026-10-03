// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTResult: outer = Optional, inner = Result
// Type: Result<A,E>? = Optional<Result<A,E>>
// Haskell: ExceptT E Maybe
//
// The applicative is the one induced by the monad (`<*> = ap`), so it is sequential and
// short-circuits exactly like `flatMapT`: the first `nil` or `.some(.failure)` in left-to-right
// order wins. Each function below is `flatMapT` + `mapT` with the bind's case analysis inlined,
// so no non-`Sendable` value is captured in a `@Sendable` closure.

/// apply for OptionalTResult: Result<(A->B),E>? -> Result<A,E>? -> Result<B,E>?
/// (<*>) = ap :: mf >>= \f -> fmap f ma
public func applyOptionalResult<A, B, E: Error>(
    _ fns: Result<@Sendable (A) -> B, E>?,
    _ values: Result<A, E>?
) -> Result<B, E>? {
    switch fns {
    case .none:
        .none

    case let .some(.failure(e)):
        .some(.failure(e))

    case let .some(.success(fn)):
        values.mapT(fn)
    }
}

/// liftA2 for OptionalTResult
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2OptionalResult<A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Result<A, E>?, Result<B, E>?) -> Result<C, E>? {
    { lhs, rhs in
        switch lhs {
        case .none:
            .none

        case let .some(.failure(e)):
            .some(.failure(e))

        case let .some(.success(a)):
            rhs.map { resultB in resultB.map { b in fn(a, b) } }
        }
    }
}

/// seqRight for OptionalTResult
/// ma *> mb = ma >>= \_ -> mb
public func seqRightOptionalResult<A, B, E: Error>(_ lhs: Result<A, E>?, _ rhs: Result<B, E>?) -> Result<B, E>? {
    switch lhs {
    case .none:
        .none

    case let .some(.failure(e)):
        .some(.failure(e))

    case .some(.success):
        rhs
    }
}

/// seqLeft for OptionalTResult
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftOptionalResult<A, B, E: Error>(_ lhs: Result<A, E>?, _ rhs: Result<B, E>?) -> Result<A, E>? {
    switch lhs {
    case .none:
        .none

    case let .some(.failure(e)):
        .some(.failure(e))

    case let .some(.success(a)):
        rhs.map { resultB in resultB.map(const(a)) }
    }
}
