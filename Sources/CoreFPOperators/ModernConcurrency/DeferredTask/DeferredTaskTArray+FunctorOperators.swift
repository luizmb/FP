import CoreFP

// (<£^>) :: (a -> b) -> DeferredTask<[a]> -> DeferredTask<[b]>
public func <£^> <A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<[A]>
) -> DeferredTask<[B]> {
    mapTDeferredTaskArray(fn, task)
}

// (<&^>) :: DeferredTask<[a]> -> (a -> b) -> DeferredTask<[b]>
public func <&^> <A: Sendable, B: Sendable>(
    _ task: DeferredTask<[A]>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredTask<[B]> {
    mapTDeferredTaskArray(fn, task)
}
