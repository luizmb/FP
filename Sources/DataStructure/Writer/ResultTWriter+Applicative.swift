import Foundation
import CoreFP

// ResultTWriter: outer = Result, inner = Writer
// Type: Result<Writer<W, A>, E>

/// apply for ResultTWriter: Result<Writer<W,(A->B)>,E> -> Result<Writer<W,A>,E> -> Result<Writer<W,B>,E>
public func applyResultWriter<W: Monoid, A, B, E: Error>(
    _ rf: Result<Writer<W, (A) -> B>, E>,
    _ ra: Result<Writer<W, A>, E>
) -> Result<Writer<W, B>, E> {
    rf.flatMap { wf in ra.map { wa in Writer<W, B>(wf.value(wa.value), W.combine(wf.log, wa.log)) } }
}

/// liftA2 for ResultTWriter
public func liftA2ResultWriter<W: Monoid, A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (Result<Writer<W, A>, E>, Result<Writer<W, B>, E>) -> Result<Writer<W, C>, E> {
    { ra, rb in
        ra.flatMap { wa in rb.map { wb in Writer<W, C>(fn(wa.value, wb.value), W.combine(wa.log, wb.log)) } }
    }
}

/// seqRight for ResultTWriter
public func seqRightResultWriter<W: Monoid, A, B, E: Error>(
    _ lhs: Result<Writer<W, A>, E>,
    _ rhs: Result<Writer<W, B>, E>
) -> Result<Writer<W, B>, E> {
    lhs.flatMap { wa in rhs.map { wb in Writer<W, B>(wb.value, W.combine(wa.log, wb.log)) } }
}

/// seqLeft for ResultTWriter
public func seqLeftResultWriter<W: Monoid, A, B, E: Error>(
    _ lhs: Result<Writer<W, A>, E>,
    _ rhs: Result<Writer<W, B>, E>
) -> Result<Writer<W, A>, E> {
    lhs.flatMap { wa in rhs.map { wb in Writer<W, A>(wa.value, W.combine(wa.log, wb.log)) } }
}
