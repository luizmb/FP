import CoreFP
import DataStructure
import Foundation
import CoreFPOperators

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <B1, A, B>(_ transform: @escaping (B) -> B1, _ either: Either<A, B>) -> Either<A, B1> {
    Either<A, B>.fmap(transform)(either)
}

// ($>) :: Either<A, B> -> b0 -> Either<A, b0>
public func £> <B1, A, B>(_ either: Either<A, B>, _ value: B1) -> Either<A, B1> {
    either.match(caseLeft: Either.left, caseRight: const(.right(value)))
}

// (<$) :: b0 -> Either<A, B> -> Either<A, b0>
public func <£ <B1, A, B>(_ value: B1, _ either: Either<A, B>) -> Either<A, B1> {
    either £> value
}
