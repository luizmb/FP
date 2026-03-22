import CoreFP

// DeferredStreamTValidation: outer = DeferredStream, inner = Validation
// Type: DeferredStream<Validation<E, A>>
// Applicative accumulates errors (Validation's key property)

public func liftA2TDeferredStreamValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredStream<Validation<E, A>>, DeferredStream<Validation<E, B>>) -> DeferredStream<Validation<E, C>> {
    { @Sendable sa, sb in
        let outer = sa
        let inner = sb
        return DeferredStream<Validation<E, C>> {
            AsyncStream<Validation<E, C>> { continuation in
                let task = Task { @Sendable in
                    var ia = outer.makeAsyncIterator()
                    var ib = inner.makeAsyncIterator()
                    while let va = await ia.next(), let vb = await ib.next() {
                        continuation.yield(Validation<E, C>.liftA2(fn)(va, vb))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }
}

public func applyTDeferredStreamValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fns: DeferredStream<Validation<E, @Sendable (A) -> B>>,
    _ values: DeferredStream<Validation<E, A>>
) -> DeferredStream<Validation<E, B>> where B: Sendable {
    DeferredStream<Validation<E, B>> {
        AsyncStream<Validation<E, B>> { continuation in
            let task = Task { @Sendable in
                var fi = fns.makeAsyncIterator()
                var vi = values.makeAsyncIterator()
                while let vf = await fi.next(), let va = await vi.next() {
                    let result: Validation<E, B> = switch (vf, va) {
                    case let (.success(f), .success(a)): .success(f(a))
                    case let (.failure(e), .success):    .failure(e)
                    case let (.success, .failure(e)):    .failure(e)
                    case let (.failure(e1), .failure(e2)): .failure(E.combine(e1, e2))
                    }
                    continuation.yield(result)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
