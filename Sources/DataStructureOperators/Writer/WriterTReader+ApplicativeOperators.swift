import CoreFP
import DataStructure
import CoreFPOperators

// (<*>) :: Writer<w, Reader<env, (a -> b)>> -> Writer<w, Reader<env, a>> -> Writer<w, Reader<env, b>>
public func <*> <W: Monoid, Env, A, B>(
    _ wf: Writer<W, Reader<Env, (A) -> B>>,
    _ wa: Writer<W, Reader<Env, A>>
) -> Writer<W, Reader<Env, B>> {
    applyWriterReader(wf, wa)
}

// (*>) :: Writer<w, Reader<env, a>> -> Writer<w, Reader<env, b>> -> Writer<w, Reader<env, b>>
public func *> <W: Monoid, Env, A, B>(_ lhs: Writer<W, Reader<Env, A>>, _ rhs: Writer<W, Reader<Env, B>>) -> Writer<W, Reader<Env, B>> {
    seqRightWriterReader(lhs, rhs)
}

// (<*) :: Writer<w, Reader<env, a>> -> Writer<w, Reader<env, b>> -> Writer<w, Reader<env, a>>
public func <* <W: Monoid, Env, A, B>(_ lhs: Writer<W, Reader<Env, A>>, _ rhs: Writer<W, Reader<Env, B>>) -> Writer<W, Reader<Env, A>> {
    seqLeftWriterReader(lhs, rhs)
}
