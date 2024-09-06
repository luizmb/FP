import Foundation

#if canImport(Operators)
import Operators
// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A0, A, B>(_ transform: @escaping (B) -> A0, _ either: Either<A, B>) -> Either<A, A0> {
    .fmap(transform)(either)
}

// ($>) :: Either a b -> a0 -> Either a a0
public func £> <A0, A, B>(_ either: Either<A, B>, _ value: A0) -> Either<A, A0> {
    switch either {
    case let .left(a): .left(a)
    case .right: .right(value)
    }
}

// (<$) :: a0 -> Either a b -> Either a a0
public func <£ <A0, A, B>(_ value: A0, _ either: Either<A, B>) -> Either<A, A0> {
    switch either {
    case let .left(a): .left(a)
    case .right: .right(value)
    }
}
#endif

public extension Either {
    static func fmap<T0>(
        _ fn: @escaping (T0) -> U
    ) -> (Either<T, T0>) -> Either<T, U> {
        { eitherTT0 in
            eitherTT0.mapRight(fn)
        }
    }

    func mapLeft<Z>(
        _ lf: (T) -> Z
    ) -> Either<Z, U> {
        switch self {
        case let .left(left):
            return .left(lf(left))
        case let .right(right):
            return .right(right)
        }
    }

    func mapRight<Z>(
        _ rf: (U) -> Z
    ) -> Either<T, Z> {
        switch self {
        case let .left(left):
            return .left(left)
        case let .right(right):
            return .right(rf(right))
        }
    }

    func bimap<T1, U1>(
        _ lf: (T) -> T1,
        _ rf: (U) -> U1
    ) -> Either<T1, U1> {
        switch self {
        case let .left(left):
            return .left(lf(left))
        case let .right(right):
            return .right(rf(right))
        }
    }
}
