import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: Stateful<s, Writer<w, (a -> b)>> -> Stateful<s, Writer<w, a>> -> Stateful<s, Writer<w, b>>
public func <*> <S, W: Monoid, A, B>(_ sf: Stateful<S, Writer<W, (A) -> B>>, _ sa: Stateful<S, Writer<W, A>>) -> Stateful<S, Writer<W, B>> {
    applyStatefulWriter(sf, sa)
}

// (*>) :: Stateful<s, Writer<w, a>> -> Stateful<s, Writer<w, b>> -> Stateful<s, Writer<w, b>>
public func *> <S, W: Monoid, A, B>(_ lhs: Stateful<S, Writer<W, A>>, _ rhs: Stateful<S, Writer<W, B>>) -> Stateful<S, Writer<W, B>> {
    seqRightStatefulWriter(lhs, rhs)
}

// (<*) :: Stateful<s, Writer<w, a>> -> Stateful<s, Writer<w, b>> -> Stateful<s, Writer<w, a>>
public func <* <S, W: Monoid, A, B>(_ lhs: Stateful<S, Writer<W, A>>, _ rhs: Stateful<S, Writer<W, B>>) -> Stateful<S, Writer<W, A>> {
    seqLeftStatefulWriter(lhs, rhs)
}
