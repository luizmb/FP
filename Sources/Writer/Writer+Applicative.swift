import Foundation
import FP

public extension Writer {
    /// apply :: Writer<w, (input -> a)> -> Writer<w, input> -> Writer<w, a>
    /// Applies the function and combines logs left-to-right.
    /// Follows Reader/Stateful convention: `A` is the result type, `Input` is the argument type.
    static func apply<Input>(_ wf: Writer<W, (Input) -> A>, _ wa: Writer<W, Input>) -> Writer<W, A> {
        Writer<W, A>(wf.value(wa.value), W.combine(wf.log, wa.log))
    }

    func seqRight<B>(_ other: Writer<W, B>) -> Writer<W, B> {
        Writer<W, B>(other.value, W.combine(log, other.log))
    }

    func seqLeft<B>(_ other: Writer<W, B>) -> Writer<W, A> {
        Writer<W, A>(value, W.combine(log, other.log))
    }

    static func liftA2<B, C>(
        _ fn: @escaping (A, B) -> C
    ) -> (Writer<W, A>, Writer<W, B>) -> Writer<W, C> {
        { wa, wb in
            Writer<W, C>(fn(wa.value, wb.value), W.combine(wa.log, wb.log))
        }
    }
}
