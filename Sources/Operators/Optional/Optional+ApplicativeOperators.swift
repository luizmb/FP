import FP
import Foundation

// (<*>) :: Optional<(a -> b)> -> Optional<a> -> Optional<b>
public func <*> <A, A0>(_ lhs: Optional<(A0) -> A>, _ rhs: Optional<A0>) -> Optional<A> {
    Optional<A>.apply(lhs, rhs)
}

// (*>) :: Optional<a> -> Optional<b> -> Optional<b>
public func *> <A, Ignore>(_ lhs: Optional<Ignore>, _ rhs: Optional<A>) -> Optional<A> {
    lhs.seqRight(rhs)
}

// (<*) :: Optional<a> -> Optional<b> -> Optional<a>
public func <* <A, Ignore>(_ lhs: Optional<A>, _ rhs: Optional<Ignore>) -> Optional<A> {
    lhs.seqLeft(rhs)
}
