import CoreFP
import CoreFPOperators

// (<*>) :: DeferredTask (a -> b) -> DeferredTask a -> DeferredTask b
public func <*> <A: Sendable, B: Sendable>(
    _ fns: DeferredTask<@Sendable (A) -> B>,
    _ values: DeferredTask<A>
) -> DeferredTask<B> {
    applyDeferredTask(fns, values)
}

// (*>) :: DeferredTask a -> DeferredTask b -> DeferredTask b
public func *> <A: Sendable, B: Sendable>(
    _ lhs: DeferredTask<A>,
    _ rhs: DeferredTask<B>
) -> DeferredTask<B> {
    lhs.seqRight(rhs)
}

// (<*) :: DeferredTask a -> DeferredTask b -> DeferredTask a
public func <* <A: Sendable, B: Sendable>(
    _ lhs: DeferredTask<A>,
    _ rhs: DeferredTask<B>
) -> DeferredTask<A> {
    lhs.seqLeft(rhs)
}
