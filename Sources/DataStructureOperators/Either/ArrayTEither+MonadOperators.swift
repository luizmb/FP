import DataStructure
import CoreFPOperators

// ArrayTEither: outer = Array, inner = Either
// Type: [Either<L,A>]

// (>>-) :: [Either<l,a>] -> (a -> [Either<l,b>]) -> [Either<l,b>]
public func >>- <L, A, B>(_ arr: [Either<L, A>], _ fn: @escaping (A) -> [Either<L, B>]) -> [Either<L, B>] {
    arr.flatMapT(fn)
}

// (-<<) :: (a -> [Either<l,b>]) -> [Either<l,a>] -> [Either<l,b>]
public func -<< <L, A, B>(_ fn: @escaping (A) -> [Either<L, B>], _ arr: [Either<L, A>]) -> [Either<L, B>] {
    arr.flatMapT(fn)
}

// (>=>) :: (a -> [Either<l,b>]) -> (b -> [Either<l,c>]) -> a -> [Either<l,c>]
public func >=> <L, A, B, C>(
    _ fn1: @escaping (A) -> [Either<L, B>],
    _ fn2: @escaping (B) -> [Either<L, C>]
) -> (A) -> [Either<L, C>] {
    { a in fn1(a).flatMapT(fn2) }
}
