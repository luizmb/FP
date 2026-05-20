import CoreFP
import Foundation

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>

/// apply for ReaderTWriter: Reader<Env,Writer<W,(A->B)>> -> Reader<Env,Writer<W,A>> -> Reader<Env,Writer<W,B>>
public func applyReaderWriter<Env, W: Monoid, A, B>(
    _ rf: Reader<Env, Writer<W, (A) -> B>>,
    _ ra: Reader<Env, Writer<W, A>>
) -> Reader<Env, Writer<W, B>> {
    Reader { env in Writer<W, B>.apply(rf(env), ra(env)) }
}

/// liftA2 for ReaderTWriter
public func liftA2ReaderWriter<Env, W: Monoid, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, Writer<W, A>>, Reader<Env, Writer<W, B>>) -> Reader<Env, Writer<W, C>> {
    { ra, rb in
        Reader { env in Writer<W, C>(fn(ra(env).value, rb(env).value), W.combine(ra(env).log, rb(env).log)) }
    }
}

/// seqRight for ReaderTWriter
public func seqRightReaderWriter<Env, W: Monoid, A, B>(
    _ lhs: Reader<Env, Writer<W, A>>,
    _ rhs: Reader<Env, Writer<W, B>>
) -> Reader<Env, Writer<W, B>> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderTWriter
public func seqLeftReaderWriter<Env, W: Monoid, A, B>(
    _ lhs: Reader<Env, Writer<W, A>>,
    _ rhs: Reader<Env, Writer<W, B>>
) -> Reader<Env, Writer<W, A>> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
