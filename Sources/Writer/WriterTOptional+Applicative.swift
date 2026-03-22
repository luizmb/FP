import Foundation
import FP

// WriterT + Optional — free functions for Writer<W, A?>

/// apply for Writer<W, Optional>
public func applyWriterOptional<W: Monoid, A, B>(
    _ wf: Writer<W, Optional<(A) -> B>>,
    _ wa: Writer<W, Optional<A>>
) -> Writer<W, Optional<B>> {
    Writer<W, Optional<B>>(
        Optional.apply(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, Optional>
public func liftA2WriterOptional<W: Monoid, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Writer<W, A?>, Writer<W, B?>) -> Writer<W, C?> {
    { wa, wb in
        Writer<W, C?>(
            Optional.liftA2(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, Optional>
public func seqRightWriterOptional<W: Monoid, A, B>(
    _ lhs: Writer<W, A?>,
    _ rhs: Writer<W, B?>
) -> Writer<W, B?> {
    Writer<W, B?>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, Optional>
public func seqLeftWriterOptional<W: Monoid, A, B>(
    _ lhs: Writer<W, A?>,
    _ rhs: Writer<W, B?>
) -> Writer<W, A?> {
    Writer<W, A?>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
