import FP
import Either
import Operators

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <A, B, B1>(_ either: Either<A, B>, _ fn: @escaping (B) -> Either<A, B1>) -> Either<A, B1> {
    either.flatMap(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <A, B, B1>(_ fn: @escaping (B) -> Either<A, B1>, _ either: Either<A, B>) -> Either<A, B1> {
    either.flatMap(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A, B0, B, B1>(
    _ fn1: @escaping (B0) -> Either<A, B>,
    _ fn2: @escaping (B) -> Either<A, B1>
) -> (B0) -> Either<A, B1> {
    Either.kleisli(fn1, fn2)
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <A, B, B1>(_ either: Either<A, B>, _ transform: @escaping (B) -> B1) -> Either<A, B1> {
    either.mapRight(transform)
}

// (<|>) :: Alternative f => f a -> f a -> f a
public func <|> <A, B>(_ lhs: Either<A, B>, _ rhs: @autoclosure () -> Either<A, B>) -> Either<A, B> {
    Either.alt(lhs, rhs())
}
