import FP
import Either
import Foundation
import Operators

// (<*>) :: Either a (b0 -> b) -> Either a b0 -> Either a b
public func <*> <A, B0, B>(_ lhs: Either<A, (B0) -> B>, _ rhs: Either<A, B0>) -> Either<A, B> {
    .specialRightRight(lhs: lhs, rhs: rhs, handling: call)
}

// (*>) :: Either a ignore -> Either a b -> Either a b
public func *> <A, Ignore, B>(_ lhs: Either<A, Ignore>, _ rhs: Either<A, B>) -> Either<A, B> {
    .specialRightRight(lhs: lhs, rhs: rhs, handling: untuple(\.1))
}

// (<*) :: Either a b -> Either a ignore -> Either a b
public func <* <A, B, Ignore>(_ lhs: Either<A, B>, _ rhs: Either<A, Ignore>) -> Either<A, B> {
    rhs *> lhs
}
