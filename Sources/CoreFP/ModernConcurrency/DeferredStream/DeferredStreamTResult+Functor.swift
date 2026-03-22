// DeferredStreamTResult: outer = DeferredStream, inner = Result
// Type: DeferredStream<Result<A, E>>  — Haskell: ExceptT e DeferredStream

public func mapTDeferredStreamResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<Result<A, E>>
) -> DeferredStream<Result<B, E>> {
    stream.fmap { result in result.map(fn) }
}

public func fmapTDeferredStreamResult<A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredStream<Result<A, E>>) -> DeferredStream<Result<B, E>> {
    { @Sendable stream in mapTDeferredStreamResult(fn, stream) }
}
