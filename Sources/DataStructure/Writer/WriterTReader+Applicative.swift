import Foundation
import Core

// WriterT + Reader — free functions for Writer<W, Reader<Env, A>>

/// apply for Writer<W, Reader>
/// Both outer logs are accumulated eagerly; the functions and values are composed in the reader.
public func applyWriterReader<W: Monoid, Env, A, B>(
    _ wf: Writer<W, Reader<Env, (A) -> B>>,
    _ wa: Writer<W, Reader<Env, A>>
) -> Writer<W, Reader<Env, B>> {
    Writer<W, Reader<Env, B>>(
        Reader.apply(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

/// liftA2 for Writer<W, Reader>
public func liftA2WriterReader<W: Monoid, Env, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Writer<W, Reader<Env, A>>, Writer<W, Reader<Env, B>>) -> Writer<W, Reader<Env, C>> {
    { wa, wb in
        Writer<W, Reader<Env, C>>(
            Reader.liftA2(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

/// seqRight for Writer<W, Reader>
public func seqRightWriterReader<W: Monoid, Env, A, B>(
    _ lhs: Writer<W, Reader<Env, A>>,
    _ rhs: Writer<W, Reader<Env, B>>
) -> Writer<W, Reader<Env, B>> {
    Writer<W, Reader<Env, B>>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

/// seqLeft for Writer<W, Reader>
public func seqLeftWriterReader<W: Monoid, Env, A, B>(
    _ lhs: Writer<W, Reader<Env, A>>,
    _ rhs: Writer<W, Reader<Env, B>>
) -> Writer<W, Reader<Env, A>> {
    Writer<W, Reader<Env, A>>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
