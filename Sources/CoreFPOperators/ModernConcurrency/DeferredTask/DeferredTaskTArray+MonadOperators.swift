import CoreFP
import CoreFPOperators

// (>>-) :: DeferredTask<[a]> -> (a -> DeferredTask<[b]>) -> DeferredTask<[b]>
public func >>- <A: Sendable, B: Sendable>(
    _ task: DeferredTask<[A]>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<[B]>
) -> DeferredTask<[B]> {
    flatMapTDeferredTaskArray(task, fn)
}

// (-<<) :: (a -> DeferredTask<[b]>) -> DeferredTask<[a]> -> DeferredTask<[b]>
public func -<< <A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<[B]>,
    _ task: DeferredTask<[A]>
) -> DeferredTask<[B]> {
    task >>- fn
}
