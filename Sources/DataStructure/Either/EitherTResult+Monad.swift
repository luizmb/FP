// SPDX-License-Identifier: Apache-2.0
import Foundation

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A,E>>
// Haskell: ExceptT e (Either L) — two independent error channels

/// flatMapT for Either<L, Result<A,E>>
/// .left(l)           → .left(l)
/// .right(.failure(e)) → .right(.failure(e))
/// .right(.success(a)) → fn(a)
public func flatMapTEitherResult<L, A, B, E: Error>(
    _ either: Either<L, Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> Either<L, Result<B, E>>
) -> Either<L, Result<B, E>> {
    either.flatMap { result in
        switch result {
        case let .failure(e):
            .right(.failure(e))

        case let .success(a):
            fn(a)
        }
    }
}

/// Curried version
public func bindTEitherResult<L, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> Either<L, Result<B, E>>
) -> (Either<L, Result<A, E>>) -> Either<L, Result<B, E>> {
    { either in flatMapTEitherResult(either, fn) }
}

/// Kleisli composition for `EitherT + Result` (left-to-right)
/// (>=>) :: (a -> Either<l,Result<b,e>>) -> (b -> Either<l,Result<c,e>>) -> a -> Either<l,Result<c,e>>
public func kleisliT<L, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Either<L, Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> Either<L, Result<C, E>>
) -> (A) -> Either<L, Result<C, E>> {
    { a in flatMapTEitherResult(fn1(a), fn2) }
}
