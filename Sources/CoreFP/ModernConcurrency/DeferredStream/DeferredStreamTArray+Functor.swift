// DeferredStreamTArray: outer = DeferredStream, inner = Array
// Type: DeferredStream<[A]>  — Haskell: ListT DeferredStream

public func mapTDeferredStreamArray<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<[A]>
) -> DeferredStream<[B]> {
    stream.map { arr in arr.map(fn) }
}

public func fmapTDeferredStreamArray<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredStream<[A]>) -> DeferredStream<[B]> {
    { @Sendable stream in mapTDeferredStreamArray(fn, stream) }
}
