import CoreFPOperators
import DataStructure
import Foundation

// (<*>) :: Either<a, (b0 -> b)> -> Either<a, b0> -> Either<a, b>
public func <*> <A: Sendable, B0: Sendable, B: Sendable>(_ lhs: Either<A, @Sendable (B0) -> B>, _ rhs: Either<A, B0>) -> Either<A, B> {
    Either<A, B>.apply(lhs, rhs)
}

// (*>) :: Either<a, ignore> -> Either<a, b> -> Either<a, b>
public func *> <A: Sendable, Ignore: Sendable, B: Sendable>(_ lhs: Either<A, Ignore>, _ rhs: Either<A, B>) -> Either<A, B> {
    lhs.seqRight(rhs)
}

// (<*) :: Either<a, b> -> Either<a, ignore> -> Either<a, b>
public func <* <A: Sendable, B: Sendable, Ignore: Sendable>(_ lhs: Either<A, B>, _ rhs: Either<A, Ignore>) -> Either<A, B> {
    lhs.seqLeft(rhs)
}
