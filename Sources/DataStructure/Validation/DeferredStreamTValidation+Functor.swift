import CoreFP

// DeferredStreamTValidation: outer = DeferredStream, inner = Validation
// Type: DeferredStream<Validation<E, A>>

public func mapTDeferredStreamValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<Validation<E, A>>
) -> DeferredStream<Validation<E, B>> {
    stream.fmap { v in v.mapSuccess(fn) }
}

public func fmapTDeferredStreamValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredStream<Validation<E, A>>) -> DeferredStream<Validation<E, B>> {
    { @Sendable stream in mapTDeferredStreamValidation(fn, stream) }
}
