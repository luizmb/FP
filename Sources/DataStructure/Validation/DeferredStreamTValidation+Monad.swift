import CoreFP

// DeferredStreamTValidation: outer = DeferredStream, inner = Validation
// Type: DeferredStream<Validation<E, A>>
// Note: Monad here is sequential (bind short-circuits on .failure — use Applicative for accumulation)

public func flatMapTDeferredStreamValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ stream: DeferredStream<Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<Validation<E, B>>
) -> DeferredStream<Validation<E, B>> {
    let s = stream
    return DeferredStream<Validation<E, B>> {
        AsyncStream<Validation<E, B>> { continuation in
            let task = Task { @Sendable in
                for await v in s {
                    switch v {
                    case let .success(a):
                        for await vb in fn(a) {
                            continuation.yield(vb)
                        }
                    case let .failure(e):
                        continuation.yield(.failure(e))
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

public func bindTDeferredStreamValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<Validation<E, B>>
) -> @Sendable (DeferredStream<Validation<E, A>>) -> DeferredStream<Validation<E, B>> {
    { @Sendable stream in flatMapTDeferredStreamValidation(stream, fn) }
}
