import FP
import Foundation

// (<*>) :: Result<(a0 -> a), b> -> Result<a0, b> -> Result<a, b>
public func <*> <A, A0, B>(_ lhs: Result<(A0) -> A, B>, _ rhs: Result<A0, B>) -> Result<A, B> {
    lhs.flatMap { fn in rhs.map(fn) }
}

// (*>) :: Result<ignore, b> -> Result<a, b> -> Result<a, b>
public func *> <A, Ignore, B>(_ lhs: Result<Ignore, B>, _ rhs: Result<A, B>) -> Result<A, B> {
    lhs.flatMap { _ in rhs }
}

// (<*) :: Result<a, b> -> Result<ignore, b> -> Result<a, b>
public func <* <A, B, Ignore>(_ lhs: Result<A, B>, _ rhs: Result<Ignore, B>) -> Result<A, B> {
    rhs *> lhs
}
