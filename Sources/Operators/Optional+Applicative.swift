import FP
import Foundation

// (<*>) :: Either a (b0 -> b) -> Either a b0 -> Either a b
public func <*> <A, A0>(_ lhs: Optional<(A0) -> A>, _ rhs: Optional<A0>) -> Optional<A> {
    Optional<((A0) -> A, A0)>.zip(lhs, rhs).map(call)
}

// (*>) :: Either a ignore -> Either a b -> Either a b
public func *> <A, Ignore>(_ lhs: Optional<Ignore>, _ rhs: Optional<A>) -> Optional<A> {
    Optional<(Ignore, A)>.zip(lhs, rhs).map(untuple(\.1))
}

// (<*) :: Either a b -> Either a ignore -> Either a b
public func <* <A, Ignore>(_ lhs: Optional<A>, _ rhs: Optional<Ignore>) -> Optional<A> {
    rhs *> lhs
}
