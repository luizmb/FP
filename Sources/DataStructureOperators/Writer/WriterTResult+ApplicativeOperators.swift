import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Writer<w, Result<(a -> b), e>> -> Writer<w, Result<a, e>> -> Writer<w, Result<b, e>>
public func <*> <W: Monoid, A, B, E: Error>(_ wf: Writer<W, Result<(A) -> B, E>>, _ wa: Writer<W, Result<A, E>>) -> Writer<W, Result<B, E>> {
    applyWriterResult(wf, wa)
}

// (*>) :: Writer<w, Result<a, e>> -> Writer<w, Result<b, e>> -> Writer<w, Result<b, e>>
public func *> <W: Monoid, A, B, E: Error>(_ lhs: Writer<W, Result<A, E>>, _ rhs: Writer<W, Result<B, E>>) -> Writer<W, Result<B, E>> {
    seqRightWriterResult(lhs, rhs)
}

// (<*) :: Writer<w, Result<a, e>> -> Writer<w, Result<b, e>> -> Writer<w, Result<a, e>>
public func <* <W: Monoid, A, B, E: Error>(_ lhs: Writer<W, Result<A, E>>, _ rhs: Writer<W, Result<B, E>>) -> Writer<W, Result<A, E>> {
    seqLeftWriterResult(lhs, rhs)
}
