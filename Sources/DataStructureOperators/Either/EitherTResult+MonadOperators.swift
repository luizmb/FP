import CoreFPOperators
import DataStructure

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A,E>>

// (>>-) :: Either<l,Result<a,e>> -> (a -> Either<l,Result<b,e>>) -> Either<l,Result<b,e>>
public func >>- <L, A, B, E: Error>(
    _ either: Either<L, Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> Either<L, Result<B, E>>
) -> Either<L, Result<B, E>> {
    flatMapTEitherResult(either, fn)
}

// (-<<) :: (a -> Either<l,Result<b,e>>) -> Either<l,Result<a,e>> -> Either<l,Result<b,e>>
public func -<< <L, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> Either<L, Result<B, E>>,
    _ either: Either<L, Result<A, E>>
) -> Either<L, Result<B, E>> {
    flatMapTEitherResult(either, fn)
}

// (>=>) :: (a -> Either<l,Result<b,e>>) -> (b -> Either<l,Result<c,e>>) -> a -> Either<l,Result<c,e>>
public func >=> <L, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Either<L, Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> Either<L, Result<C, E>>
) -> (A) -> Either<L, Result<C, E>> {
    { a in flatMapTEitherResult(fn1(a), fn2) }
}
