import CoreFPOperators
import DataStructure

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <S, F, B>(
    _ loading: Loading<S, F>,
    _ f: @escaping (S) -> Loading<B, F>
) -> Loading<B, F> {
    loading.flatMap(f)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <S, F, B>(
    _ f: @escaping (S) -> Loading<B, F>,
    _ loading: Loading<S, F>
) -> Loading<B, F> {
    loading.flatMap(f)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A, S, F, B>(
    _ fn1: @escaping (A) -> Loading<S, F>,
    _ fn2: @escaping (S) -> Loading<B, F>
) -> (A) -> Loading<B, F> {
    Loading<S, F>.kleisli(fn1, fn2)
}

// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
public func <=< <A, S, F, B>(
    _ fn2: @escaping (S) -> Loading<B, F>,
    _ fn1: @escaping (A) -> Loading<S, F>
) -> (A) -> Loading<B, F> {
    Loading<S, F>.kleisliBack(fn2, fn1)
}
