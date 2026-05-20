import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: Writer<w, Either<l, (a -> b)>> -> Writer<w, Either<l, a>> -> Writer<w, Either<l, b>>
public func <*> <W: Monoid, L: Sendable, A: Sendable, B: Sendable>(_ wf: Writer<W, Either<L, @Sendable (A) -> B>>, _ wa: Writer<W, Either<L, A>>) -> Writer<W, Either<L, B>> {
    applyWriterEither(wf, wa)
}

// (*>) :: Writer<w, Either<l, a>> -> Writer<w, Either<l, b>> -> Writer<w, Either<l, b>>
public func *> <W: Monoid, L: Sendable, A: Sendable, B: Sendable>(_ lhs: Writer<W, Either<L, A>>, _ rhs: Writer<W, Either<L, B>>) -> Writer<W, Either<L, B>> {
    seqRightWriterEither(lhs, rhs)
}

// (<*) :: Writer<w, Either<l, a>> -> Writer<w, Either<l, b>> -> Writer<w, Either<l, a>>
public func <* <W: Monoid, L: Sendable, A: Sendable, B: Sendable>(_ lhs: Writer<W, Either<L, A>>, _ rhs: Writer<W, Either<L, B>>) -> Writer<W, Either<L, A>> {
    seqLeftWriterEither(lhs, rhs)
}
