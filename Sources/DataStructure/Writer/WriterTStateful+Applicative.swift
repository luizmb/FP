import CoreFP
import Foundation

// WriterT + Stateful — free functions for Writer<W, Stateful<S, A>>

/// apply for Writer<W, Stateful>
/// Both outer logs are accumulated eagerly; the state threads through the composed stateful.
public func applyWriterStateful<W: Monoid, S, A, B>(
    _ wf: Writer<W, Stateful<S, (A) -> B>>,
    _ wa: Writer<W, Stateful<S, A>>
) -> Writer<W, Stateful<S, B>> {
    Writer<W, Stateful<S, B>>(
        Stateful<S, B>.apply(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, Stateful>
public func liftA2WriterStateful<W: Monoid, S, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Writer<W, Stateful<S, A>>, Writer<W, Stateful<S, B>>) -> Writer<W, Stateful<S, C>> {
    { wa, wb in
        Writer<W, Stateful<S, C>>(
            Stateful.liftA2(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, Stateful>
public func seqRightWriterStateful<W: Monoid, S, A, B>(
    _ lhs: Writer<W, Stateful<S, A>>,
    _ rhs: Writer<W, Stateful<S, B>>
) -> Writer<W, Stateful<S, B>> {
    Writer<W, Stateful<S, B>>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, Stateful>
public func seqLeftWriterStateful<W: Monoid, S, A, B>(
    _ lhs: Writer<W, Stateful<S, A>>,
    _ rhs: Writer<W, Stateful<S, B>>
) -> Writer<W, Stateful<S, A>> {
    Writer<W, Stateful<S, A>>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
