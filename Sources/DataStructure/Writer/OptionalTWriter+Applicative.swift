import CoreFP
import Foundation

// OptionalTWriter: outer = Optional, inner = Writer
// Type: Writer<W, A>? = Optional<Writer<W, A>>

/// apply for OptionalTWriter: Writer<W,(A->B)>? -> Writer<W,A>? -> Writer<W,B>?
public func applyOptionalWriter<W: Monoid, A, B>(
    _ wf: Writer<W, @Sendable (A) -> B>?,
    _ wa: Writer<W, A>?
) -> Writer<W, B>? {
    wf.flatMap { f in wa.map { a in Writer<W, B>(f.value(a.value), W.combine(f.log, a.log)) } }
}

/// liftA2 for OptionalTWriter
public func liftA2OptionalWriter<W: Monoid, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, A>?, Writer<W, B>?) -> Writer<W, C>? {
    { wa, wb in
        wa.flatMap { a in wb.map { b in Writer<W, C>(fn(a.value, b.value), W.combine(a.log, b.log)) } }
    }
}

/// seqRight for OptionalTWriter
public func seqRightOptionalWriter<W: Monoid, A, B>(
    _ lhs: Writer<W, A>?,
    _ rhs: Writer<W, B>?
) -> Writer<W, B>? {
    lhs.flatMap { wa in rhs.map { wb in Writer<W, B>(wb.value, W.combine(wa.log, wb.log)) } }
}

/// seqLeft for OptionalTWriter
public func seqLeftOptionalWriter<W: Monoid, A, B>(
    _ lhs: Writer<W, A>?,
    _ rhs: Writer<W, B>?
) -> Writer<W, A>? {
    lhs.flatMap { wa in rhs.map { wb in Writer<W, A>(wa.value, W.combine(wa.log, wb.log)) } }
}
