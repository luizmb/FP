import DataStructure
import CoreFPOperators

// (<*>) :: [Stateful<s, (a -> b)>] -> [Stateful<s, a>] -> [Stateful<s, b>]
public func <*> <S, A, B>(_ fns: [Stateful<S, (A) -> B>], _ vals: [Stateful<S, A>]) -> [Stateful<S, B>] {
    applyArrayStateful(fns, vals)
}

// (*>) :: [Stateful<s, a>] -> [Stateful<s, b>] -> [Stateful<s, b>]
public func *> <S, A, B>(_ lhs: [Stateful<S, A>], _ rhs: [Stateful<S, B>]) -> [Stateful<S, B>] {
    seqRightArrayStateful(lhs, rhs)
}

// (<*) :: [Stateful<s, a>] -> [Stateful<s, b>] -> [Stateful<s, a>]
public func <* <S, A, B>(_ lhs: [Stateful<S, A>], _ rhs: [Stateful<S, B>]) -> [Stateful<S, A>] {
    seqLeftArrayStateful(lhs, rhs)
}
