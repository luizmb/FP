import CoreFP

// DeferredTaskTValidation: outer = DeferredTask, inner = Validation
// Type: DeferredTask<Validation<E, A>>
// Applicative accumulates errors (Validation's key property)

public func liftA2TDeferredTaskValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredTask<Validation<E, A>>, DeferredTask<Validation<E, B>>) -> DeferredTask<Validation<E, C>> {
    { @Sendable ta, tb in
        DeferredTask<Validation<E, C>> {
            let va = await ta.run()
            let vb = await tb.run()
            return Validation<E, C>.liftA2(fn)(va, vb)
        }
    }
}

public func applyTDeferredTaskValidation<E: Semigroup & Sendable, A: Sendable, B: Sendable>(
    _ fns: DeferredTask<Validation<E, @Sendable (A) -> B>>,
    _ values: DeferredTask<Validation<E, A>>
) -> DeferredTask<Validation<E, B>> where B: Sendable {
    DeferredTask<Validation<E, B>> {
        let vf = await fns.run()
        let va = await values.run()
        return switch (vf, va) {
        case let (.success(f), .success(a)): Validation<E, B>.success(f(a))
        case let (.failure(e), .success):    Validation<E, B>.failure(e)
        case let (.success, .failure(e)):    Validation<E, B>.failure(e)
        case let (.failure(e1), .failure(e2)): Validation<E, B>.failure(E.combine(e1, e2))
        }
    }
}
