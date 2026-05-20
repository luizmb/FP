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
        case .failure(let e): .right(.failure(e))
        case .success(let a): fn(a)
        }
    }
}

/// Curried version
public func bindTEitherResult<L, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> Either<L, Result<B, E>>
) -> (Either<L, Result<A, E>>) -> Either<L, Result<B, E>> {
    { either in flatMapTEitherResult(either, fn) }
}
