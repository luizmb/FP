import Foundation
import CoreFP

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A,E>> = two error types

/// mapT for Either<L, Result<A,E>>
public func mapTEitherResult<L, A, B, E: Error>(
    _ fn: @escaping (A) -> B,
    _ either: Either<L, Result<A, E>>
) -> Either<L, Result<B, E>> {
    either.mapRight { result in result.map(fn) }
}

/// Curried fmapT
public func fmapTEitherResult<L, A, B, E: Error>(
    _ fn: @escaping (A) -> B
) -> (Either<L, Result<A, E>>) -> Either<L, Result<B, E>> {
    { either in mapTEitherResult(fn, either) }
}
