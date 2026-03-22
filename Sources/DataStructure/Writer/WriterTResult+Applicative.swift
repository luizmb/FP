import Foundation
import Core

// WriterT + Result — free functions for Writer<W, Result<A, E>>

/// apply for Writer<W, Result>
public func applyWriterResult<W: Monoid, A, B, E: Error>(
    _ wf: Writer<W, Result<(A) -> B, E>>,
    _ wa: Writer<W, Result<A, E>>
) -> Writer<W, Result<B, E>> {
    Writer<W, Result<B, E>>(
        Result.apply(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, Result>
public func liftA2WriterResult<W: Monoid, A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (Writer<W, Result<A, E>>, Writer<W, Result<B, E>>) -> Writer<W, Result<C, E>> {
    { wa, wb in
        Writer<W, Result<C, E>>(
            Result.liftA2(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, Result>
public func seqRightWriterResult<W: Monoid, A, B, E: Error>(
    _ lhs: Writer<W, Result<A, E>>,
    _ rhs: Writer<W, Result<B, E>>
) -> Writer<W, Result<B, E>> {
    Writer<W, Result<B, E>>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, Result>
public func seqLeftWriterResult<W: Monoid, A, B, E: Error>(
    _ lhs: Writer<W, Result<A, E>>,
    _ rhs: Writer<W, Result<B, E>>
) -> Writer<W, Result<A, E>> {
    Writer<W, Result<A, E>>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
