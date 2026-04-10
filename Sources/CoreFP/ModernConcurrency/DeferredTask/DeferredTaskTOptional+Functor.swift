// DeferredTaskTOptional: outer = DeferredTask, inner = Optional
// Type: DeferredTask<A?>  — Haskell: MaybeT DeferredTask

public func mapTDeferredTaskOptional<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ task: DeferredTask<A?>
) -> DeferredTask<B?> {
    task.map { optA in optA.map(fn) }
}

public func fmapTDeferredTaskOptional<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredTask<A?>) -> DeferredTask<B?> {
    { @Sendable task in mapTDeferredTaskOptional(fn, task) }
}
