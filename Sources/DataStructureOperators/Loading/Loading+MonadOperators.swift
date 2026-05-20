import CoreFPOperators
import DataStructure

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <S, F, B: Sendable>(
    _ loading: Loading<S, F>,
    _ f: @escaping @Sendable (S) -> Loading<B, F>
) -> Loading<B, F> {
    loading.flatMap(f)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <S, F, B: Sendable>(
    _ f: @escaping @Sendable (S) -> Loading<B, F>,
    _ loading: Loading<S, F>
) -> Loading<B, F> {
    loading.flatMap(f)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A, S, F, B: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Loading<S, F>,
    _ fn2: @escaping @Sendable (S) -> Loading<B, F>
) -> @Sendable (A) -> Loading<B, F> {
    Loading<S, F>.kleisli(fn1, fn2)
}

// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
public func <=< <A, S, F, B: Sendable>(
    _ fn2: @escaping @Sendable (S) -> Loading<B, F>,
    _ fn1: @escaping @Sendable (A) -> Loading<S, F>
) -> @Sendable (A) -> Loading<B, F> {
    Loading<S, F>.kleisliBack(fn2, fn1)
}
