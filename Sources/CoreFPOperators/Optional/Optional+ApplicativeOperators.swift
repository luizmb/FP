import CoreFP
import Foundation

// (<*>) :: Optional<(a -> b)> -> Optional<a> -> Optional<b>
public func <*> <A, A0>(_ lhs: ((A0) -> A)?, _ rhs: A0?) -> A? {
    A?.apply(lhs, rhs)
}

// (*>) :: Optional<a> -> Optional<b> -> Optional<b>
public func *> <A, Ignore>(_ lhs: Ignore?, _ rhs: A?) -> A? {
    lhs.seqRight(rhs)
}

// (<*) :: Optional<a> -> Optional<b> -> Optional<a>
public func <* <A, Ignore>(_ lhs: A?, _ rhs: Ignore?) -> A? {
    lhs.seqLeft(rhs)
}
