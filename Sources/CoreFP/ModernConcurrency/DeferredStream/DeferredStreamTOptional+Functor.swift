// DeferredStreamTOptional: outer = DeferredStream, inner = Optional
// Type: DeferredStream<A?>  — Haskell: MaybeT DeferredStream

// mapT maps inside the Optional, leaving the DeferredStream layer intact
public func mapTDeferredStreamOptional<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<A?>
) -> DeferredStream<B?> {
    stream.map { optA in optA.map(fn) }
}

public func fmapTDeferredStreamOptional<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredStream<A?>) -> DeferredStream<B?> {
    { @Sendable stream in mapTDeferredStreamOptional(fn, stream) }
}
