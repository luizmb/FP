import CoreFP

// (<*>) :: DeferredStream<[a->b]> -> DeferredStream<[a]> -> DeferredStream<[b]>
public func <*> <A: Sendable, B: Sendable>(
    _ fns: DeferredStream<[@Sendable (A) -> B]>,
    _ values: DeferredStream<[A]>
) -> DeferredStream<[B]> {
    applyTDeferredStreamArray(fns, values)
}
