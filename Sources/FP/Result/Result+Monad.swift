import Foundation

public extension Result {
    /// Curried version of Swift's native flatMap for functional composition
    /// (>>=) :: m a -> (a -> m b) -> m b
    static func bind<A1>(
        _ fn: @escaping (Success) -> Result<A1, Failure>
    ) -> (Result<Success, Failure>) -> Result<A1, Failure> {
        { result in
            result.flatMap(fn)
        }
    }

    /// Kleisli composition (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<A0, A1>(
        _ fn1: @escaping (A0) -> Result<Success, Failure>,
        _ fn2: @escaping (Success) -> Result<A1, Failure>
    ) -> (A0) -> Result<A1, Failure> {
        { a0 in
            fn1(a0).flatMap(fn2)
        }
    }

    /// Kleisli composition (right-to-left)
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<A0, A1>(
        _ fn2: @escaping (Success) -> Result<A1, Failure>,
        _ fn1: @escaping (A0) -> Result<Success, Failure>
    ) -> (A0) -> Result<A1, Failure> {
        { a0 in
            fn1(a0).flatMap(fn2)
        }
    }

    /// Alternative operation - returns the first success, or the last failure
    /// (<|>) :: m a -> m a -> m a
    static func alt(_ lhs: Result<Success, Failure>, _ rhs: @autoclosure () -> Result<Success, Failure>) -> Result<Success, Failure> {
        switch lhs {
        case .success: lhs
        case .failure: rhs()
        }
    }

    /// Monadic join - flattens nested Results
    /// join :: m (m a) -> m a
    static func join<A>(_ nested: Result<Result<A, Failure>, Failure>) -> Result<A, Failure> {
        nested.flatMap(id)
    }

    /// Discards the success value, keeping only the structure
    /// void :: m a -> m ()
    func void() -> Result<Void, Failure> {
        map(ignore)
    }
}
