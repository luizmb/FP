import DataStructure
import CoreFPOperators

// EitherTStateful: outer = Either, inner = Stateful
// Type: Either<L, Stateful<S, A>>

// (>>-) :: Either<l, Stateful<s, a>> -> (a -> Stateful<s, b>) -> Either<l, Stateful<s, b>>
public func >>- <L, S, A, B>(_ either: Either<L, Stateful<S, A>>, _ fn: @escaping (A) -> Stateful<S, B>) -> Either<L, Stateful<S, B>> {
    either.flatMapT(fn)
}

// (-<<) :: (a -> Stateful<s, b>) -> Either<l, Stateful<s, a>> -> Either<l, Stateful<s, b>>
public func -<< <L, S, A, B>(_ fn: @escaping (A) -> Stateful<S, B>, _ either: Either<L, Stateful<S, A>>) -> Either<L, Stateful<S, B>> {
    either.flatMapT(fn)
}

// (>=>) :: (a -> Either<l, Stateful<s, b>>) -> (b -> Stateful<s, c>) -> a -> Either<l, Stateful<s, c>>
public func >=> <L, S, A, B, C>(
    _ fn1: @escaping (A) -> Either<L, Stateful<S, B>>,
    _ fn2: @escaping (B) -> Stateful<S, C>
) -> (A) -> Either<L, Stateful<S, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
