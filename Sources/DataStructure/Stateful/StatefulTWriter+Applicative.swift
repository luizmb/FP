import CoreFP
import Foundation

// StatefulTWriter: outer = Stateful, inner = Writer
// Type: Stateful<S, Writer<W, A>>

/// apply for StatefulTWriter: Stateful<S,Writer<W,(A->B)>> -> Stateful<S,Writer<W,A>> -> Stateful<S,Writer<W,B>>
public func applyStatefulWriter<S, W: Monoid, A, B>(
    _ sf: Stateful<S, Writer<W, (A) -> B>>,
    _ sa: Stateful<S, Writer<W, A>>
) -> Stateful<S, Writer<W, B>> {
    Stateful<S, Writer<W, B>> { s in
        let wf = sf.run(&s)
        let wa = sa.run(&s)
        return Writer<W, B>(wf.value(wa.value), W.combine(wf.log, wa.log))
    }
}

/// liftA2 for StatefulTWriter
public func liftA2StatefulWriter<S, W: Monoid, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Stateful<S, Writer<W, A>>, Stateful<S, Writer<W, B>>) -> Stateful<S, Writer<W, C>> {
    { sa, sb in
        Stateful<S, Writer<W, C>> { s in
            let wa = sa.run(&s)
            let wb = sb.run(&s)
            return Writer<W, C>(fn(wa.value, wb.value), W.combine(wa.log, wb.log))
        }
    }
}

/// seqRight for StatefulTWriter
public func seqRightStatefulWriter<S, W: Monoid, A, B>(
    _ lhs: Stateful<S, Writer<W, A>>,
    _ rhs: Stateful<S, Writer<W, B>>
) -> Stateful<S, Writer<W, B>> {
    Stateful<S, Writer<W, B>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for StatefulTWriter
public func seqLeftStatefulWriter<S, W: Monoid, A, B>(
    _ lhs: Stateful<S, Writer<W, A>>,
    _ rhs: Stateful<S, Writer<W, B>>
) -> Stateful<S, Writer<W, A>> {
    Stateful<S, Writer<W, A>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
