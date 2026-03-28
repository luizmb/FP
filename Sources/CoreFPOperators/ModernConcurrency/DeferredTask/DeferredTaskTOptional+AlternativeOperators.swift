import CoreFP

// (<|>) :: DeferredTask<A?> -> DeferredTask<A?> -> DeferredTask<A?>
// Race: returns first non-nil result; cancels the other task on win.
public func <|> <A: Sendable>(
    _ lhs: DeferredTask<A?>,
    _ rhs: @autoclosure () -> DeferredTask<A?>
) -> DeferredTask<A?> {
    altDeferredTaskOptional(lhs, rhs())
}
