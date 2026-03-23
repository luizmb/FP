import DataStructure
import CoreFP
import CoreFPOperators

// ReaderTDeferredTask: outer = Reader, inner = DeferredTask
// Type: Reader<Env, DeferredTask<A>>

// (>>-) :: Reader<env, DeferredTask<a>> -> (a -> Reader<env, DeferredTask<b>>) -> Reader<env, DeferredTask<b>>
public func >>- <Env: Sendable, A: Sendable, B: Sendable>(
    _ reader: Reader<Env, DeferredTask<A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, DeferredTask<B>>
) -> Reader<Env, DeferredTask<B>> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> Reader<env, DeferredTask<b>>) -> Reader<env, DeferredTask<a>> -> Reader<env, DeferredTask<b>>
public func -<< <Env: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, DeferredTask<B>>,
    _ reader: Reader<Env, DeferredTask<A>>
) -> Reader<Env, DeferredTask<B>> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> Reader<env, DeferredTask<b>>) -> (b -> Reader<env, DeferredTask<c>>) -> a -> Reader<env, DeferredTask<c>>
public func >=> <Env: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, DeferredTask<B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, DeferredTask<C>>
) -> (A) -> Reader<Env, DeferredTask<C>> {
    { a in fn1(a).flatMapT(fn2) }
}
