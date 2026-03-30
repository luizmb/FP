import CoreFP
import DataStructure
import CoreFPOperators

// (<*>) :: Writer<w, Validation<e,(a->b)>> -> Writer<w, Validation<e,a>> -> Writer<w, Validation<e,b>>
public func <*> <W: Monoid, E: Semigroup, A, B>(
    _ wf: Writer<W, Validation<E, (A) -> B>>,
    _ wa: Writer<W, Validation<E, A>>
) -> Writer<W, Validation<E, B>> {
    applyWriterValidation(wf, wa)
}

// (*>) :: Writer<w, Validation<e,a>> -> Writer<w, Validation<e,b>> -> Writer<w, Validation<e,b>>
public func *> <W: Monoid, E: Semigroup, A, B>(
    _ lhs: Writer<W, Validation<E, A>>,
    _ rhs: Writer<W, Validation<E, B>>
) -> Writer<W, Validation<E, B>> {
    seqRightWriterValidation(lhs, rhs)
}

// (<*) :: Writer<w, Validation<e,a>> -> Writer<w, Validation<e,b>> -> Writer<w, Validation<e,a>>
public func <* <W: Monoid, E: Semigroup, A, B>(
    _ lhs: Writer<W, Validation<E, A>>,
    _ rhs: Writer<W, Validation<E, B>>
) -> Writer<W, Validation<E, A>> {
    seqLeftWriterValidation(lhs, rhs)
}
