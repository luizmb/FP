import CoreFPOperators
import DataStructure

// MARK: - ReaderT + Either

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env: Sendable, L: Sendable, A: Sendable, B: Sendable>(
    _ reader: Reader<Env, Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, Either<L, B>>
) -> Reader<Env, Either<L, B>> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env: Sendable, L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, Either<L, B>>,
    _ reader: Reader<Env, Either<L, A>>
) -> Reader<Env, Either<L, B>> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env: Sendable, L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Either<L, B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Either<L, C>>
) -> (A) -> Reader<Env, Either<L, C>> {
    { a in fn1(a).flatMapT(fn2) }
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <Env, L, A, B>(
    _ reader: Reader<Env, Either<L, A>>,
    _ transform: @escaping @Sendable (A) -> B
) -> Reader<Env, Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    reader.mapT(transform)
}
