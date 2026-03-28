// DeferredTaskTOptional: Alternative
// Type: DeferredTask<A?>

// altT :: DeferredTask<A?> -> DeferredTask<A?> -> DeferredTask<A?>
// Runs both tasks concurrently; returns the first non-nil result.
// If both return nil, returns nil. The other task is cancelled on first win.
public func altDeferredTaskOptional<A: Sendable>(
    _ lhs: DeferredTask<A?>,
    _ rhs: @autoclosure () -> DeferredTask<A?>
) -> DeferredTask<A?> {
    let captured = rhs()
    return DeferredTask {
        await withTaskGroup(of: A?.self) { group in
            group.addTask { await lhs.run() }
            group.addTask { await captured.run() }
            for await value in group {
                if let v = value { group.cancelAll(); return v }
            }
            return nil
        }
    }
}
