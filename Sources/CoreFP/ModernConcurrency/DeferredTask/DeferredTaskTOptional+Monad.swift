// DeferredTaskTOptional: outer = DeferredTask, inner = Optional
// Type: DeferredTask<A?>

// flatMapT :: DeferredTask<A?> -> (A -> DeferredTask<B?>) -> DeferredTask<B?>
// nil short-circuits; Some(a) proceeds through fn
public func flatMapTDeferredTaskOptional<A: Sendable, B: Sendable>(
    _ task: DeferredTask<A?>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<B?>
) -> DeferredTask<B?> {
    task.flatMap { optA in
        guard let a = optA else { return .pure(nil) }
        return fn(a)
    }
}

public func bindTDeferredTaskOptional<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<B?>
) -> @Sendable (DeferredTask<A?>) -> DeferredTask<B?> {
    { @Sendable task in flatMapTDeferredTaskOptional(task, fn) }
}
