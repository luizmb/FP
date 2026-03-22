import CoreFP

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <A, A1, B>(_ result: Result<A, B>, _ fn: @escaping (A) -> Result<A1, B>) -> Result<A1, B> {
    result.flatMap(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <A, A1, B>(_ fn: @escaping (A) -> Result<A1, B>, _ result: Result<A, B>) -> Result<A1, B> {
    result.flatMap(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A0, A, A1, B>(
    _ fn1: @escaping (A0) -> Result<A, B>,
    _ fn2: @escaping (A) -> Result<A1, B>
) -> (A0) -> Result<A1, B> {
    Result.kleisli(fn1, fn2)
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <A, A1, B>(_ result: Result<A, B>, _ transform: @escaping (A) -> A1) -> Result<A1, B> {
    result.map(transform)
}

// (<|>) :: Alternative f => f a -> f a -> f a
public func <|> <A, B>(_ lhs: Result<A, B>, _ rhs: @autoclosure () -> Result<A, B>) -> Result<A, B> {
    Result.alt(lhs, rhs())
}
