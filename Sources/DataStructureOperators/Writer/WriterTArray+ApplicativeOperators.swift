import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: Writer<w, [(a -> b)]> -> Writer<w, [a]> -> Writer<w, [b]>
public func <*> <W: Monoid, A, B>(_ wf: Writer<W, [@Sendable (A) -> B]>, _ wa: Writer<W, [A]>) -> Writer<W, [B]> {
    applyWriterArray(wf, wa)
}

// (*>) :: Writer<w, [a]> -> Writer<w, [b]> -> Writer<w, [b]>
public func *> <W: Monoid, A, B>(_ lhs: Writer<W, [A]>, _ rhs: Writer<W, [B]>) -> Writer<W, [B]> {
    seqRightWriterArray(lhs, rhs)
}

// (<*) :: Writer<w, [a]> -> Writer<w, [b]> -> Writer<w, [a]>
public func <* <W: Monoid, A, B>(_ lhs: Writer<W, [A]>, _ rhs: Writer<W, [B]>) -> Writer<W, [A]> {
    seqLeftWriterArray(lhs, rhs)
}
