import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Reader<env, DeferredTask<(a -> b)>> -> Reader<env, DeferredTask<a>> -> Reader<env, DeferredTask<b>>
public func <*> <Env, A: Sendable, B: Sendable>(_ rf: Reader<Env, DeferredTask<@Sendable (A) -> B>>, _ ra: Reader<Env, DeferredTask<A>>) -> Reader<Env, DeferredTask<B>> {
    applyReaderDeferredTask(rf, ra)
}

// (*>) :: Reader<env, DeferredTask<a>> -> Reader<env, DeferredTask<b>> -> Reader<env, DeferredTask<b>>
public func *> <Env, A: Sendable, B: Sendable>(_ lhs: Reader<Env, DeferredTask<A>>, _ rhs: Reader<Env, DeferredTask<B>>) -> Reader<Env, DeferredTask<B>> {
    seqRightReaderDeferredTask(lhs, rhs)
}

// (<*) :: Reader<env, DeferredTask<a>> -> Reader<env, DeferredTask<b>> -> Reader<env, DeferredTask<a>>
public func <* <Env, A: Sendable, B: Sendable>(_ lhs: Reader<Env, DeferredTask<A>>, _ rhs: Reader<Env, DeferredTask<B>>) -> Reader<Env, DeferredTask<A>> {
    seqLeftReaderDeferredTask(lhs, rhs)
}
