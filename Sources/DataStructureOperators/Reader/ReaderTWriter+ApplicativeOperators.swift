import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Reader<env, Writer<w, (a -> b)>> -> Reader<env, Writer<w, a>> -> Reader<env, Writer<w, b>>
public func <*> <Env, W: Monoid, A, B>(_ rf: Reader<Env, Writer<W, (A) -> B>>, _ ra: Reader<Env, Writer<W, A>>) -> Reader<Env, Writer<W, B>> {
    applyReaderWriter(rf, ra)
}

// (*>) :: Reader<env, Writer<w, a>> -> Reader<env, Writer<w, b>> -> Reader<env, Writer<w, b>>
public func *> <Env, W: Monoid, A, B>(_ lhs: Reader<Env, Writer<W, A>>, _ rhs: Reader<Env, Writer<W, B>>) -> Reader<Env, Writer<W, B>> {
    seqRightReaderWriter(lhs, rhs)
}

// (<*) :: Reader<env, Writer<w, a>> -> Reader<env, Writer<w, b>> -> Reader<env, Writer<w, a>>
public func <* <Env, W: Monoid, A, B>(_ lhs: Reader<Env, Writer<W, A>>, _ rhs: Reader<Env, Writer<W, B>>) -> Reader<Env, Writer<W, A>> {
    seqLeftReaderWriter(lhs, rhs)
}
