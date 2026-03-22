import Foundation
import CoreFP

public extension Either {
    /// Monadic bind operation for Either
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMap<B1>(_ fn: @escaping (B) -> Either<A, B1>) -> Either<A, B1> {
        match(
            caseLeft: Either<A, B1>.left,
            caseRight: fn
        )
    }

    /// Curried version of flatMap for functional composition
    /// (>>=) :: m a -> (a -> m b) -> m b
    static func bind<B1>(
        _ fn: @escaping (B) -> Either<A, B1>
    ) -> (Either<A, B>) -> Either<A, B1> {
        { either in
            either.flatMap(fn)
        }
    }

    /// Kleisli composition (left-to-right)
    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<B0, B1>(
        _ fn1: @escaping (B0) -> Either<A, B>,
        _ fn2: @escaping (B) -> Either<A, B1>
    ) -> (B0) -> Either<A, B1> {
        { b0 in
            fn1(b0).flatMap(fn2)
        }
    }

    /// Kleisli composition (right-to-left)
    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<B0, B1>(
        _ fn2: @escaping (B) -> Either<A, B1>,
        _ fn1: @escaping (B0) -> Either<A, B>
    ) -> (B0) -> Either<A, B1> {
        { b0 in
            fn1(b0).flatMap(fn2)
        }
    }

    /// Alternative operation - returns the first Right, or the last Left
    /// (<|>) :: m a -> m a -> m a
    static func alt(_ lhs: Either<A, B>, _ rhs: @autoclosure () -> Either<A, B>) -> Either<A, B> {
        lhs.match(
            caseLeft: const(rhs()),
            caseRight: const(lhs)
        )
    }

    /// Monadic join - flattens nested Eithers
    /// join :: m (m a) -> m a
    static func join<B1>(_ nested: Either<A, Either<A, B1>>) -> Either<A, B1> where B == Either<A, B1> {
        nested.flatMap(CoreFP.id)
    }

    /// Discards the right value, keeping only the structure
    /// void :: m a -> m ()
    func void() -> Either<A, Void> {
        mapRight(const(()))
    }
}
