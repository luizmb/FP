import Core

// MARK: - Monad

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <A, A1>(_ array: [A], _ fn: @escaping (A) -> [A1]) -> [A1] {
    array.flatMap(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <A, A1>(_ fn: @escaping (A) -> [A1], _ array: [A]) -> [A1] {
    array.flatMap(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A0, A, A1>(
    _ fn1: @escaping (A0) -> [A],
    _ fn2: @escaping (A) -> [A1]
) -> (A0) -> [A1] {
    Array.kleisli(fn1, fn2)
}
