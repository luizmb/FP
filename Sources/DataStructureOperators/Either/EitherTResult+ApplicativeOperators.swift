import CoreFPOperators
import DataStructure

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A,E>>

// (<*>) :: Either<l,Result<(a->b),e>> -> Either<l,Result<a,e>> -> Either<l,Result<b,e>>
public func <*> <L, A, B, E: Error>(
    _ fns: Either<L, Result<@Sendable (A) -> B, E>>,
    _ values: Either<L, Result<A, E>>
) -> Either<L, Result<B, E>> {
    applyEitherResult(fns, values)
}

// (*>) :: Either<l,Result<a,e>> -> Either<l,Result<b,e>> -> Either<l,Result<b,e>>
public func *> <L, A, B, E: Error>(
    _ lhs: Either<L, Result<A, E>>,
    _ rhs: Either<L, Result<B, E>>
) -> Either<L, Result<B, E>> {
    seqRightEitherResult(lhs, rhs)
}

// (<*) :: Either<l,Result<a,e>> -> Either<l,Result<b,e>> -> Either<l,Result<a,e>>
public func <* <L, A, B, E: Error>(
    _ lhs: Either<L, Result<A, E>>,
    _ rhs: Either<L, Result<B, E>>
) -> Either<L, Result<A, E>> {
    seqLeftEitherResult(lhs, rhs)
}
