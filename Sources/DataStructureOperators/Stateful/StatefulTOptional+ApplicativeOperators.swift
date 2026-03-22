import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Stateful<s, (a -> b)?> -> Stateful<s, a?> -> Stateful<s, b?>
public func <*> <S, A, B>(_ sf: Stateful<S, ((A) -> B)?>, _ sa: Stateful<S, A?>) -> Stateful<S, B?> {
    applyStatefulOptional(sf, sa)
}

// (*>) :: Stateful<s, a?> -> Stateful<s, b?> -> Stateful<s, b?>
public func *> <S, A, B>(_ lhs: Stateful<S, A?>, _ rhs: Stateful<S, B?>) -> Stateful<S, B?> {
    seqRightStatefulOptional(lhs, rhs)
}

// (<*) :: Stateful<s, a?> -> Stateful<s, b?> -> Stateful<s, a?>
public func <* <S, A, B>(_ lhs: Stateful<S, A?>, _ rhs: Stateful<S, B?>) -> Stateful<S, A?> {
    seqLeftStatefulOptional(lhs, rhs)
}
