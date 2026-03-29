import CoreFP
import Foundation

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A,E>>

/// apply for EitherTResult
public func applyEitherResult<L, A, B, E: Error>(
    _ fns: Either<L, Result<(A) -> B, E>>,
    _ values: Either<L, Result<A, E>>
) -> Either<L, Result<B, E>> {
    Either.liftA2(Result.apply)(fns, values)
}

/// liftA2 for EitherTResult
public func liftA2EitherResult<L, A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (Either<L, Result<A, E>>, Either<L, Result<B, E>>) -> Either<L, Result<C, E>> {
    Either.liftA2(Result.liftA2(fn))
}

/// seqRight for EitherTResult
public func seqRightEitherResult<L, A, B, E: Error>(
    _ lhs: Either<L, Result<A, E>>,
    _ rhs: Either<L, Result<B, E>>
) -> Either<L, Result<B, E>> {
    Either.liftA2({ (a: Result<A, E>, b: Result<B, E>) in a.seqRight(b) })(lhs, rhs)
}

/// seqLeft for EitherTResult
public func seqLeftEitherResult<L, A, B, E: Error>(
    _ lhs: Either<L, Result<A, E>>,
    _ rhs: Either<L, Result<B, E>>
) -> Either<L, Result<A, E>> {
    Either.liftA2({ (a: Result<A, E>, b: Result<B, E>) in a.seqLeft(b) })(lhs, rhs)
}
