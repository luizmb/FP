import CoreFP
import Foundation

// ReaderTDeferredStream: outer = Reader, inner = DeferredStream
// Type: Reader<Env, DeferredStream<A>>

/// apply for ReaderTDeferredStream: Reader<Env,DeferredStream<(A->B)>> -> Reader<Env,DeferredStream<A>> -> Reader<Env,DeferredStream<B>>
public func applyReaderDeferredStream<Env, A: Sendable, B: Sendable>(
    _ rf: Reader<Env, DeferredStream<@Sendable (A) -> B>>,
    _ ra: Reader<Env, DeferredStream<A>>
) -> Reader<Env, DeferredStream<B>> {
    Reader { env in applyDeferredStream(rf(env), ra(env)) }
}

/// liftA2 for ReaderTDeferredStream
public func liftA2ReaderDeferredStream<Env, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, DeferredStream<A>>, Reader<Env, DeferredStream<B>>) -> Reader<Env, DeferredStream<C>> {
    { ra, rb in
        Reader { env in liftA2DeferredStream(fn)(ra(env), rb(env)) }
    }
}

/// seqRight for ReaderTDeferredStream
public func seqRightReaderDeferredStream<Env, A: Sendable, B: Sendable>(
    _ lhs: Reader<Env, DeferredStream<A>>,
    _ rhs: Reader<Env, DeferredStream<B>>
) -> Reader<Env, DeferredStream<B>> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderTDeferredStream
public func seqLeftReaderDeferredStream<Env, A: Sendable, B: Sendable>(
    _ lhs: Reader<Env, DeferredStream<A>>,
    _ rhs: Reader<Env, DeferredStream<B>>
) -> Reader<Env, DeferredStream<A>> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
