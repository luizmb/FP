// DeferredTaskTResult: Alternative
// Type: DeferredTask<Result<A, E>>

// altT :: DeferredTask<Result<A,E>> -> DeferredTask<Result<A,E>> -> DeferredTask<Result<A,E>>
// Runs both tasks concurrently; returns the first .success.
// If both fail, returns the last failure. The other task is cancelled on first win.
public func altDeferredTaskResult<A: Sendable, E: Error & Sendable>(
    _ lhs: DeferredTask<Result<A, E>>,
    _ rhs: @autoclosure () -> DeferredTask<Result<A, E>>
) -> DeferredTask<Result<A, E>> {
    let captured = rhs()
    return DeferredTask {
        await withTaskGroup(of: Result<A, E>.self) { group in
            group.addTask { await lhs.run() }
            group.addTask { await captured.run() }
            if let first = await group.next() {
                if case .success = first { group.cancelAll(); return first }
                if let second = await group.next() { return second }
                return first
            }
            // Unreachable: the group always has 2 tasks.
            return await lhs.run()
        }
    }
}
