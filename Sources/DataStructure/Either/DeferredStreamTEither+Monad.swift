import CoreFP

// DeferredStreamTEither: outer = DeferredStream, inner = Either
// Type: DeferredStream<Either<L, A>>

// flatMapT: .left propagates; .right(a) proceeds through fn
public func flatMapTDeferredStreamEither<L: Sendable, A: Sendable, B: Sendable>(
    _ stream: DeferredStream<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<Either<L, B>>
) -> DeferredStream<Either<L, B>> {
    let s = stream
    return DeferredStream<Either<L, B>> {
        AsyncStream<Either<L, B>> { continuation in
            Task { @Sendable in
                for await either in s {
                    switch either {
                    case let .right(a):
                        for await b in fn(a) {
                            continuation.yield(b)
                        }
                    case let .left(l):
                        continuation.yield(.left(l))
                    }
                }
                continuation.finish()
            }
        }
    }
}

public func bindTDeferredStreamEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<Either<L, B>>
) -> @Sendable (DeferredStream<Either<L, A>>) -> DeferredStream<Either<L, B>> {
    { @Sendable stream in flatMapTDeferredStreamEither(stream, fn) }
}
