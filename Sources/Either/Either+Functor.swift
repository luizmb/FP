import Foundation
import FP

#if canImport(Operators)
import Operators
// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <B1, A, B>(_ transform: @escaping (B) -> B1, _ either: Either<A, B>) -> Either<A, B1> 
where B: Sendable, B1: Sendable, A: Sendable {
    .fmap(transform)(either)
}

// ($>) :: Either a b -> a0 -> Either a a0
public func £> <B1, A, B>(_ either: Either<A, B>, _ value: B1) -> Either<A, B1> {
    either.match(caseLeft: Either.left, caseRight: const(.right(value)))
}

// (<$) :: a0 -> Either a b -> Either a a0
public func <£ <B1, A, B>(_ value: B1, _ either: Either<A, B>) -> Either<A, B1> {
    either £> value
}
#endif

public extension Either {
    static func fmap<B0>(
        _ fn: @escaping (B0) -> B
    ) -> (Either<A, B0>) -> Either<A, B> where Self: Sendable {
        { previous in previous.mapRight(fn) }
    }

    func mapLeft<A1>(
        _ lf: @escaping (A) -> A1
    ) -> Either<A1, B> {
        match(
            caseLeft: compose(lf, Either<A1, B>.left),
            caseRight: Either<A1, B>.right
        )
    }

    func mapRight<B1>(
        _ rf: @escaping (B) -> B1
    ) -> Either<A, B1> {
        match(
            caseLeft: Either<A, B1>.left,
            caseRight: compose(rf, Either<A, B1>.right)
        )
    }

    func bimap<A1, B1>(
        _ lf: @escaping (A) -> A1,
        _ rf: @escaping (B) -> B1
    ) -> Either<A1, B1> {
        match(
            caseLeft: compose(lf, Either<A1, B1>.left),
            caseRight: compose(rf, Either<A1, B1>.right)
        )
    }
}
