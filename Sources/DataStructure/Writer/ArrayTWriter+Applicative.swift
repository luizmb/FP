import CoreFP
import Foundation

// ArrayTWriter: outer = Array, inner = Writer
// Type: [Writer<W, A>]

/// apply for ArrayTWriter: [Writer<W,(A->B)>] -> [Writer<W,A>] -> [Writer<W,B>]
public func applyArrayWriter<W: Monoid, A, B>(
    _ fns: [Writer<W, (A) -> B>],
    _ vals: [Writer<W, A>]
) -> [Writer<W, B>] {
    fns.flatMap { wf in vals.map { wa in Writer<W, B>(wf.value(wa.value), W.combine(wf.log, wa.log)) } }
}

/// liftA2 for ArrayTWriter
public func liftA2ArrayWriter<W: Monoid, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> ([Writer<W, A>], [Writer<W, B>]) -> [Writer<W, C>] {
    { arrA, arrB in
        arrA.flatMap { wa in arrB.map { wb in Writer<W, C>(fn(wa.value, wb.value), W.combine(wa.log, wb.log)) } }
    }
}

/// seqRight for ArrayTWriter
public func seqRightArrayWriter<W: Monoid, A, B>(
    _ lhs: [Writer<W, A>],
    _ rhs: [Writer<W, B>]
) -> [Writer<W, B>] {
    lhs.flatMap { wa in rhs.map { wb in Writer<W, B>(wb.value, W.combine(wa.log, wb.log)) } }
}

/// seqLeft for ArrayTWriter
public func seqLeftArrayWriter<W: Monoid, A, B>(
    _ lhs: [Writer<W, A>],
    _ rhs: [Writer<W, B>]
) -> [Writer<W, A>] {
    lhs.flatMap { wa in rhs.map { wb in Writer<W, A>(wa.value, W.combine(wa.log, wb.log)) } }
}
