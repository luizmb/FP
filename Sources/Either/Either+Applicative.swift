import Foundation

#if canImport(Operators)
import Operators
// (<*>) :: Either e (a -> b) -> Either e a -> Either e b
public func <*> <E, A, B>(_ lhs: Either<E, (A) -> B>, _ rhs: Either<E, A>) -> Either<E, B> {
    switch (lhs, rhs) {
    case
        let (.left(value), .left),
        let (.left(value), .right),
        let (.right, .left(value)):
        .left(value)
    case let (.right(fn), .right(value)):
        .right(fn(value))
    }
}

// (*>) :: Either e a -> Either e b -> Either e b
public func *> <E, A, B>(_ lhs: Either<E, A>, _ rhs: Either<E, B>) -> Either<E, B> {
    switch (lhs, rhs) {
    case
        let (.left(value), .left),
        let (.left(value), .right),
        let (.right, .left(value)):
        .left(value)
    case let (.right, .right(value)):
        .right(value)
    }
}

// (<*) :: Either e a -> Either e b -> Either e a
public func <* <E, A, B>(_ lhs: Either<E, A>, _ rhs: Either<E, B>) -> Either<E, A> {
    switch (lhs, rhs) {
    case
        let (.left(value), .left),
        let (.left(value), .right),
        let (.right, .left(value)):
        .left(value)
    case let (.right(value), .right):
        .right(value)
    }
}
#endif

public extension Either {
    // liftA2 :: (a -> b -> c) -> Either e a -> Either e b -> Either e c
    static func liftA2 <A, B>(_ fn: @escaping (A, B) -> U) -> (Either<T, A>, Either<T, B>) -> Either<T, U> {
        { eitherA, eitherB in
            switch (eitherA, eitherB) {
            case
                let (.left(value), .left),
                let (.left(value), .right),
                let (.right, .left(value)):
                .left(value)
            case let (.right(a), .right(b)):
                .right(fn(a, b))
            }
        }
    }

    static func zip<A, B>(_ lhs: Either<T, A>, _ rhs: Either<T, B>) -> Either<T, U> where U == (A, B) {
        switch (lhs, rhs) {
        case
            let (.left(value), .left),
            let (.left(value), .right),
            let (.right, .left(value)):
            .left(value)
        case let (.right(a), .right(b)):
            .right((a, b))
        }
    }
}
