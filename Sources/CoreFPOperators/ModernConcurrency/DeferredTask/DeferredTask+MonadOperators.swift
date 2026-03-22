import CoreFP
import CoreFPOperators

// (>>-) :: DeferredTask a -> (a -> DeferredTask b) -> DeferredTask b
public func >>- <A: Sendable, B: Sendable>(
    _ task: DeferredTask<A>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<B>
) -> DeferredTask<B> {
    task.flatMap(fn)
}

// (-<<) :: (a -> DeferredTask b) -> DeferredTask a -> DeferredTask b
public func -<< <A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<B>,
    _ task: DeferredTask<A>
) -> DeferredTask<B> {
    task >>- fn
}

// (>=>) :: (a -> DeferredTask b) -> (b -> DeferredTask c) -> (a -> DeferredTask c)
public func >=> <A: Sendable, B: Sendable, C: Sendable>(
    _ f: @escaping @Sendable (A) -> DeferredTask<B>,
    _ g: @escaping @Sendable (B) -> DeferredTask<C>
) -> @Sendable (A) -> DeferredTask<C> {
    DeferredTask<A>.kleisli(f, g)
}
