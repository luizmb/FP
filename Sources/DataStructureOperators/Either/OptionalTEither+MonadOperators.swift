import CoreFPOperators
import DataStructure

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>

// (>>-) :: Either<l,a>? -> (a -> Either<l,b>?) -> Either<l,b>?
public func >>- <L, A, B>(_ opt: Either<L, A>?, _ fn: @escaping @Sendable (A) -> Either<L, B>?) -> Either<L, B>? {
    opt.flatMapT(fn)
}

// (-<<) :: (a -> Either<l,b>?) -> Either<l,a>? -> Either<l,b>?
public func -<< <L, A, B>(_ fn: @escaping @Sendable (A) -> Either<L, B>?, _ opt: Either<L, A>?) -> Either<L, B>? {
    opt.flatMapT(fn)
}

// (>=>) :: (a -> Either<l,b>?) -> (b -> Either<l,c>?) -> a -> Either<l,c>?
public func >=> <L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, B>?,
    _ fn2: @escaping @Sendable (B) -> Either<L, C>?
) -> (A) -> Either<L, C>? {
    { a in fn1(a).flatMapT(fn2) }
}
