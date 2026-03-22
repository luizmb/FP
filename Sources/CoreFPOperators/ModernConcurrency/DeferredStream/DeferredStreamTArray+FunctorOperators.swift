import CoreFP
import CoreFPOperators

// (<£>) :: (a -> b) -> DeferredStream<[a]> -> DeferredStream<[b]>
public func <£> <A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<[A]>
) -> DeferredStream<[B]> {
    mapTDeferredStreamArray(fn, stream)
}

// (<&>) :: DeferredStream<[a]> -> (a -> b) -> DeferredStream<[b]>
public func <&> <A: Sendable, B: Sendable>(
    _ stream: DeferredStream<[A]>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredStream<[B]> {
    mapTDeferredStreamArray(fn, stream)
}
