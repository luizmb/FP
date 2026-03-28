// race :: DeferredTask a -> DeferredTask a -> DeferredTask a
// Runs both tasks concurrently; returns the result of whichever completes first.
// The slower task is cancelled.
public func race<A: Sendable>(
    _ lhs: DeferredTask<A>,
    _ rhs: DeferredTask<A>
) -> DeferredTask<A> {
    DeferredTask {
        await withTaskGroup(of: A.self) { group in
            group.addTask { await lhs.run() }
            group.addTask { await rhs.run() }
            for await value in group {
                group.cancelAll()
                return value
            }
            // Unreachable: the group always has 2 tasks.
            return await lhs.run()
        }
    }
}
