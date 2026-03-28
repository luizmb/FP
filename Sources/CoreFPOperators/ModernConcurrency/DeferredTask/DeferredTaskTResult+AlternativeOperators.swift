import CoreFP

// (<|>) :: DeferredTask<Result<A,E>> -> DeferredTask<Result<A,E>> -> DeferredTask<Result<A,E>>
// Race: returns first .success; if both fail, returns the last failure.
// Cancels the other task on first win.
public func <|> <A: Sendable, E: Error & Sendable>(
    _ lhs: DeferredTask<Result<A, E>>,
    _ rhs: @autoclosure () -> DeferredTask<Result<A, E>>
) -> DeferredTask<Result<A, E>> {
    altDeferredTaskResult(lhs, rhs())
}
