import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Reader<env, DeferredStream<(a -> b)>> -> Reader<env, DeferredStream<a>> -> Reader<env, DeferredStream<b>>
public func <*> <Env, A: Sendable, B: Sendable>(_ rf: Reader<Env, DeferredStream<@Sendable (A) -> B>>, _ ra: Reader<Env, DeferredStream<A>>) -> Reader<Env, DeferredStream<B>> {
    applyReaderDeferredStream(rf, ra)
}

// (*>) :: Reader<env, DeferredStream<a>> -> Reader<env, DeferredStream<b>> -> Reader<env, DeferredStream<b>>
public func *> <Env, A: Sendable, B: Sendable>(_ lhs: Reader<Env, DeferredStream<A>>, _ rhs: Reader<Env, DeferredStream<B>>) -> Reader<Env, DeferredStream<B>> {
    seqRightReaderDeferredStream(lhs, rhs)
}

// (<*) :: Reader<env, DeferredStream<a>> -> Reader<env, DeferredStream<b>> -> Reader<env, DeferredStream<a>>
public func <* <Env, A: Sendable, B: Sendable>(_ lhs: Reader<Env, DeferredStream<A>>, _ rhs: Reader<Env, DeferredStream<B>>) -> Reader<Env, DeferredStream<A>> {
    seqLeftReaderDeferredStream(lhs, rhs)
}
