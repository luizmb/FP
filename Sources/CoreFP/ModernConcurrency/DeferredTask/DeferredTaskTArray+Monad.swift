// DeferredTaskTArray: outer = DeferredTask, inner = Array
// Type: DeferredTask<[A]>

// flatMapT :: DeferredTask<[A]> -> (A -> DeferredTask<[B]>) -> DeferredTask<[B]>
// Applies fn to each element, runs tasks sequentially, concatenates results.
public func flatMapTDeferredTaskArray<A: Sendable, B: Sendable>(
    _ task: DeferredTask<[A]>,
    _ fn: @escaping @Sendable (A) -> DeferredTask<[B]>
) -> DeferredTask<[B]> {
    task.flatMap { arr in
        DeferredTask<[B]> {
            var result: [B] = []
            for a in arr {
                let bs = await fn(a).run()
                result.append(contentsOf: bs)
            }
            return result
        }
    }
}

public func bindTDeferredTaskArray<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredTask<[B]>
) -> @Sendable (DeferredTask<[A]>) -> DeferredTask<[B]> {
    { @Sendable task in flatMapTDeferredTaskArray(task, fn) }
}
