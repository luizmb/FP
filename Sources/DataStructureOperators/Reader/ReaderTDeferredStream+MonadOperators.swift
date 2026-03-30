import CoreFP
import CoreFPOperators
import DataStructure

// ReaderTDeferredStream: outer = Reader, inner = DeferredStream
// Type: Reader<Env, DeferredStream<A>>

// (>>-) :: Reader<env, DeferredStream<a>> -> (a -> Reader<env, DeferredStream<b>>) -> Reader<env, DeferredStream<b>>
public func >>- <Env: Sendable, A: Sendable, B: Sendable>(
    _ reader: Reader<Env, DeferredStream<A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, DeferredStream<B>>
) -> Reader<Env, DeferredStream<B>> {
    reader.flatMapT(fn)
}

// (-<<) :: (a -> Reader<env, DeferredStream<b>>) -> Reader<env, DeferredStream<a>> -> Reader<env, DeferredStream<b>>
public func -<< <Env: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, DeferredStream<B>>,
    _ reader: Reader<Env, DeferredStream<A>>
) -> Reader<Env, DeferredStream<B>> {
    reader.flatMapT(fn)
}

// (>=>) :: (a -> Reader<env, DeferredStream<b>>) -> (b -> Reader<env, DeferredStream<c>>) -> a -> Reader<env, DeferredStream<c>>
public func >=> <Env: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, DeferredStream<B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, DeferredStream<C>>
) -> (A) -> Reader<Env, DeferredStream<C>> {
    { a in fn1(a).flatMapT(fn2) }
}
