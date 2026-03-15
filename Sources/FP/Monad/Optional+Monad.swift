import Foundation

public extension Optional {
    /// Curried version of Swift's native flatMap for functional composition
    /// (>>=) :: m a -> (a -> m b) -> m b
    static func bind<A1>(
        _ fn: @escaping (A) -> A1?
    ) -> (A?) -> A1? {
        { optional in
            optional.flatMap(fn)
        }
    }

    /// Kleisli composition (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<A0, A1>(
        _ fn1: @escaping (A0) -> A?,
        _ fn2: @escaping (A) -> A1?
    ) -> (A0) -> A1? {
        { a0 in
            fn1(a0).flatMap(fn2)
        }
    }

    /// Kleisli composition (right-to-left)
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<A0, A1>(
        _ fn2: @escaping (A) -> A1?,
        _ fn1: @escaping (A0) -> A?
    ) -> (A0) -> A1? {
        { a0 in
            fn1(a0).flatMap(fn2)
        }
    }

    /// Alternative operation - returns the first non-nil value
    /// (<|>) :: m a -> m a -> m a
    static func alt(_ lhs: A?, _ rhs: @autoclosure () -> A?) -> A? {
        lhs ?? rhs()
    }
}
