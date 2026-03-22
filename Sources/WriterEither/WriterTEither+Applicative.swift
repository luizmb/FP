import Foundation
import FP
import Writer
import Either

// WriterT + Either — free functions for Writer<W, Either<L, A>>

/// apply for Writer<W, Either>
public func applyWriterEither<W: Monoid, L, A, B>(
    _ wf: Writer<W, Either<L, (A) -> B>>,
    _ wa: Writer<W, Either<L, A>>
) -> Writer<W, Either<L, B>> {
    Writer<W, Either<L, B>>(
        Either.apply(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, Either>
public func liftA2WriterEither<W: Monoid, L, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Writer<W, Either<L, A>>, Writer<W, Either<L, B>>) -> Writer<W, Either<L, C>> {
    { wa, wb in
        Writer<W, Either<L, C>>(
            Either.liftA2(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, Either>
public func seqRightWriterEither<W: Monoid, L, A, B>(
    _ lhs: Writer<W, Either<L, A>>,
    _ rhs: Writer<W, Either<L, B>>
) -> Writer<W, Either<L, B>> {
    Writer<W, Either<L, B>>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, Either>
public func seqLeftWriterEither<W: Monoid, L, A, B>(
    _ lhs: Writer<W, Either<L, A>>,
    _ rhs: Writer<W, Either<L, B>>
) -> Writer<W, Either<L, A>> {
    Writer<W, Either<L, A>>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
