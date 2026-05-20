import CoreFP
import Foundation

public extension Loading {
    /// Monadic bind for `Loading`.
    /// (>>=) :: m a -> (a -> m b) -> m b
    ///
    /// Chains into a new `Loading` when the current state is `.loaded`. `.idle`, `.loading`,
    /// and `.failed` pass through unchanged (adapted to `B`); for the in-flight / error cases
    /// the `previous` value is mapped through `f` and projected via `loadedOrPrevious` so the
    /// stale-data invariant is preserved.
    func flatMap<B: Sendable>(_ f: (Success) -> Loading<B, Failure>) -> Loading<B, Failure> {
        switch self {
        case .idle:
            .idle
        case .loading(let prev):
            .loading(previous: prev.flatMap { f($0).loadedOrPrevious })
        case .loaded(let value):
            f(value)
        case let .failed(err, prev):
            .failed(error: err, previous: prev.flatMap { f($0).loadedOrPrevious })
        }
    }

    /// Curried bind for functional composition.
    /// (>>=) :: m a -> (a -> m b) -> m b
    static func bind<B: Sendable>(
        _ f: @escaping @Sendable (Success) -> Loading<B, Failure>
    ) -> (Loading<Success, Failure>) -> Loading<B, Failure> {
        { $0.flatMap(f) }
    }

    /// Kleisli composition (left-to-right).
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<A, B: Sendable>(
        _ fn1: @escaping @Sendable (A) -> Loading<Success, Failure>,
        _ fn2: @escaping @Sendable (Success) -> Loading<B, Failure>
    ) -> (A) -> Loading<B, Failure> {
        { a in fn1(a).flatMap(fn2) }
    }

    /// Kleisli composition (right-to-left).
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<A, B: Sendable>(
        _ fn2: @escaping @Sendable (Success) -> Loading<B, Failure>,
        _ fn1: @escaping @Sendable (A) -> Loading<Success, Failure>
    ) -> (A) -> Loading<B, Failure> {
        { a in fn1(a).flatMap(fn2) }
    }
}
