import CoreFP
import Foundation

// ReaderTDeferredTask: outer = Reader, inner = DeferredTask
// Type: Reader<Env, DeferredTask<A>>

/// apply for ReaderTDeferredTask: Reader<Env,DeferredTask<(A->B)>> -> Reader<Env,DeferredTask<A>> -> Reader<Env,DeferredTask<B>>
public func applyReaderDeferredTask<Env, A: Sendable, B: Sendable>(
    _ rf: Reader<Env, DeferredTask<@Sendable (A) -> B>>,
    _ ra: Reader<Env, DeferredTask<A>>
) -> Reader<Env, DeferredTask<B>> {
    Reader { env in applyDeferredTask(rf(env), ra(env)) }
}

/// liftA2 for ReaderTDeferredTask
public func liftA2ReaderDeferredTask<Env, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, DeferredTask<A>>, Reader<Env, DeferredTask<B>>) -> Reader<Env, DeferredTask<C>> {
    { ra, rb in
        Reader { env in liftA2DeferredTask(fn)(ra(env), rb(env)) }
    }
}

/// seqRight for ReaderTDeferredTask
public func seqRightReaderDeferredTask<Env, A: Sendable, B: Sendable>(
    _ lhs: Reader<Env, DeferredTask<A>>,
    _ rhs: Reader<Env, DeferredTask<B>>
) -> Reader<Env, DeferredTask<B>> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderTDeferredTask
public func seqLeftReaderDeferredTask<Env, A: Sendable, B: Sendable>(
    _ lhs: Reader<Env, DeferredTask<A>>,
    _ rhs: Reader<Env, DeferredTask<B>>
) -> Reader<Env, DeferredTask<A>> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
