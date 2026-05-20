import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: Writer<w, Stateful<s, (a -> b)>> -> Writer<w, Stateful<s, a>> -> Writer<w, Stateful<s, b>>
public func <*> <W: Monoid, S, A, B>(_ wf: Writer<W, Stateful<S, @Sendable (A) -> B>>, _ wa: Writer<W, Stateful<S, A>>) -> Writer<W, Stateful<S, B>> {
    applyWriterStateful(wf, wa)
}

// (*>) :: Writer<w, Stateful<s, a>> -> Writer<w, Stateful<s, b>> -> Writer<w, Stateful<s, b>>
public func *> <W: Monoid, S, A, B>(_ lhs: Writer<W, Stateful<S, A>>, _ rhs: Writer<W, Stateful<S, B>>) -> Writer<W, Stateful<S, B>> {
    seqRightWriterStateful(lhs, rhs)
}

// (<*) :: Writer<w, Stateful<s, a>> -> Writer<w, Stateful<s, b>> -> Writer<w, Stateful<s, a>>
public func <* <W: Monoid, S, A, B>(_ lhs: Writer<W, Stateful<S, A>>, _ rhs: Writer<W, Stateful<S, B>>) -> Writer<W, Stateful<S, A>> {
    seqLeftWriterStateful(lhs, rhs)
}
