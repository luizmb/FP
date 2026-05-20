import CoreFPOperators
import DataStructure

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <Env, O, O1>(
    _ reader: Reader<Env, O>,
    _ fn: @escaping @Sendable (O) -> Reader<Env, O1>
) -> Reader<Env, O1> {
    reader.flatMap(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <Env, O, O1>(
    _ fn: @escaping @Sendable (O) -> Reader<Env, O1>,
    _ reader: Reader<Env, O>
) -> Reader<Env, O1> {
    reader.flatMap(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <Env, O0, O, O1>(
    _ fn1: @escaping @Sendable (O0) -> Reader<Env, O>,
    _ fn2: @escaping @Sendable (O) -> Reader<Env, O1>
) -> (O0) -> Reader<Env, O1> {
    Reader.kleisli(fn1, fn2)
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <Env, O, O1>(
    _ reader: Reader<Env, O>,
    _ transform: @escaping @Sendable (O) -> O1
) -> Reader<Env, O1> {
    reader.mapReader(transform)
}
