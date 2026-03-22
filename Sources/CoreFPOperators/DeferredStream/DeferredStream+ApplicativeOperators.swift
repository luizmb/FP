import CoreFP
import CoreFPOperators

// (<*>) :: DeferredStream (a -> b) -> DeferredStream a -> DeferredStream b
public func <*> <A: Sendable, B: Sendable>(
    _ fns: DeferredStream<@Sendable (A) -> B>,
    _ values: DeferredStream<A>
) -> DeferredStream<B> {
    applyDeferredStream(fns, values)
}

// (*>) :: DeferredStream a -> DeferredStream b -> DeferredStream b
public func *> <A: Sendable, B: Sendable>(
    _ lhs: DeferredStream<A>,
    _ rhs: DeferredStream<B>
) -> DeferredStream<B> {
    lhs.seqRight(rhs)
}

// (<*) :: DeferredStream a -> DeferredStream b -> DeferredStream a
public func <* <A: Sendable, B: Sendable>(
    _ lhs: DeferredStream<A>,
    _ rhs: DeferredStream<B>
) -> DeferredStream<A> {
    lhs.seqLeft(rhs)
}
