import CoreFP
import CoreFPOperators

// (<£>) :: (a -> b) -> DeferredTask a -> DeferredTask b
public func <£> <A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<A>
) -> DeferredTask<B> {
    task.fmap(fn)
}

// (<&>) :: DeferredTask a -> (a -> b) -> DeferredTask b
public func <&> <A: Sendable, B: Sendable>(
    _ task: DeferredTask<A>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredTask<B> {
    task.fmap(fn)
}

// (£>) :: DeferredTask a -> b -> DeferredTask b
public func £> <A: Sendable, B: Sendable>(
    _ task: DeferredTask<A>,
    _ value: B
) -> DeferredTask<B> {
    task.replace(value)
}

// (<£) :: b -> DeferredTask a -> DeferredTask b
public func <£ <A: Sendable, B: Sendable>(
    _ value: B,
    _ task: DeferredTask<A>
) -> DeferredTask<B> {
    task £> value
}
