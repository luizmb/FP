/// Runs two deferred tasks concurrently and returns the result of whichever finishes first.
///
/// `race` is the competitive counterpart to `zip` / `liftA2`. Where `zip` waits for *both*
/// tasks to complete and combines their results, `race` returns the *first* result and cancels
/// the slower task immediately.
///
/// This is useful for timeout patterns, redundant network requests, or any scenario where
/// you want the fastest of two alternatives:
///
/// ```swift
/// let fastest: DeferredTask<Data> = race(fetchFromCache, fetchFromNetwork)
/// let data = await fastest.run()
/// ```
///
/// - Parameters:
///   - lhs: The first candidate task.
///   - rhs: The second candidate task.
/// - Returns: A `DeferredTask` that yields the result of the first task to complete.
///   The other task is cancelled via `TaskGroup.cancelAll()`.
///
/// - Note: Both tasks are started at the same time inside a `TaskGroup`. The implementation
///   is not biased — it returns whichever Swift `TaskGroup` dispatches first.
///
/// - SeeAlso: ``DeferredTask``
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
