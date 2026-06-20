// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// WriterT + Array — free functions for Writer<W, [A]>

/// apply for Writer<W, Array>
public func applyWriterArray<W: Monoid, A, B>(
    _ wf: Writer<W, [@Sendable (A) -> B]>,
    _ wa: Writer<W, [A]>
) -> Writer<W, [B]> {
    Writer<W, [B]>(
        wf.value.flatMap(wa.value.map),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, Array>
public func liftA2WriterArray<W: Monoid, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, [A]>, Writer<W, [B]>) -> Writer<W, [C]> {
    { wa, wb in
        Writer<W, [C]>(
            Array.liftA2(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, Array>
public func seqRightWriterArray<W: Monoid, A, B>(
    _ lhs: Writer<W, [A]>,
    _ rhs: Writer<W, [B]>
) -> Writer<W, [B]> {
    Writer<W, [B]>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, Array>
public func seqLeftWriterArray<W: Monoid, A, B>(
    _ lhs: Writer<W, [A]>,
    _ rhs: Writer<W, [B]>
) -> Writer<W, [A]> {
    Writer<W, [A]>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
