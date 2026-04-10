// DeferredTaskTArray: outer = DeferredTask, inner = Array
// Type: DeferredTask<[A]>  — Haskell: ListT DeferredTask

public func mapTDeferredTaskArray<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<[A]>
) -> DeferredTask<[B]> {
    task.map { arr in arr.map(fn) }
}

public func fmapTDeferredTaskArray<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredTask<[A]>) -> DeferredTask<[B]> {
    { @Sendable task in mapTDeferredTaskArray(fn, task) }
}
