import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: Stateful<s, Result<(a -> b), e>> -> Stateful<s, Result<a, e>> -> Stateful<s, Result<b, e>>
public func <*> <S, A, B, E: Error>(_ sf: Stateful<S, Result<(A) -> B, E>>, _ sa: Stateful<S, Result<A, E>>) -> Stateful<S, Result<B, E>> {
    applyStatefulResult(sf, sa)
}

// (*>) :: Stateful<s, Result<a, e>> -> Stateful<s, Result<b, e>> -> Stateful<s, Result<b, e>>
public func *> <S, A, B, E: Error>(_ lhs: Stateful<S, Result<A, E>>, _ rhs: Stateful<S, Result<B, E>>) -> Stateful<S, Result<B, E>> {
    seqRightStatefulResult(lhs, rhs)
}

// (<*) :: Stateful<s, Result<a, e>> -> Stateful<s, Result<b, e>> -> Stateful<s, Result<a, e>>
public func <* <S, A, B, E: Error>(_ lhs: Stateful<S, Result<A, E>>, _ rhs: Stateful<S, Result<B, E>>) -> Stateful<S, Result<A, E>> {
    seqLeftStatefulResult(lhs, rhs)
}
