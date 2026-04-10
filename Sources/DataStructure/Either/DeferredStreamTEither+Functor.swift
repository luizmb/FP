import CoreFP

// DeferredStreamTEither: outer = DeferredStream, inner = Either
// Type: DeferredStream<Either<L, A>>  — Haskell: ExceptT l DeferredStream

public func mapTDeferredStreamEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<Either<L, A>>
) -> DeferredStream<Either<L, B>> {
    stream.map { either in either.mapRight(fn) }
}

public func fmapTDeferredStreamEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (DeferredStream<Either<L, A>>) -> DeferredStream<Either<L, B>> {
    { @Sendable stream in mapTDeferredStreamEither(fn, stream) }
}
