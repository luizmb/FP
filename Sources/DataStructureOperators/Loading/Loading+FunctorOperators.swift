import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <S, F, B>(
    _ transform: @escaping (S) -> B,
    _ loading: Loading<S, F>
) -> Loading<B, F> {
    Loading<S, F>.fmap(transform)(loading)
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <S, F, B>(
    _ loading: Loading<S, F>,
    _ transform: @escaping (S) -> B
) -> Loading<B, F> {
    loading.map(transform)
}

// ($>) :: f a -> b -> f b
public func £> <S, F, B>(_ loading: Loading<S, F>, _ value: B) -> Loading<B, F> {
    loading.map { _ in value }
}

// (<$) :: b -> f a -> f b
public func <£ <S, F, B>(_ value: B, _ loading: Loading<S, F>) -> Loading<B, F> {
    loading £> value
}
