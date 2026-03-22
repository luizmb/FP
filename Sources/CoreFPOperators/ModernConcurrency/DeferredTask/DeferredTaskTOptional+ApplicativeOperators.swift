import CoreFP
import CoreFPOperators

// (<*>) :: DeferredTask<(a->b)?> -> DeferredTask<a?> -> DeferredTask<b?>
public func <*> <A: Sendable, B: Sendable>(
    _ fns: DeferredTask<(@Sendable (A) -> B)?>,
    _ values: DeferredTask<A?>
) -> DeferredTask<B?> {
    applyTDeferredTaskOptional(fns, values)
}
