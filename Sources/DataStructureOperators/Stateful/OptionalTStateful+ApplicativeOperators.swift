import CoreFPOperators
import DataStructure

// (<*>) :: Stateful<s, (a -> b)>? -> Stateful<s, a>? -> Stateful<s, b>?
public func <*> <S, A, B>(_ sf: Stateful<S, (A) -> B>?, _ sa: Stateful<S, A>?) -> Stateful<S, B>? {
    applyOptionalStateful(sf, sa)
}

// (*>) :: Stateful<s, a>? -> Stateful<s, b>? -> Stateful<s, b>?
public func *> <S, A, B>(_ lhs: Stateful<S, A>?, _ rhs: Stateful<S, B>?) -> Stateful<S, B>? {
    seqRightOptionalStateful(lhs, rhs)
}

// (<*) :: Stateful<s, a>? -> Stateful<s, b>? -> Stateful<s, a>?
public func <* <S, A, B>(_ lhs: Stateful<S, A>?, _ rhs: Stateful<S, B>?) -> Stateful<S, A>? {
    seqLeftOptionalStateful(lhs, rhs)
}
