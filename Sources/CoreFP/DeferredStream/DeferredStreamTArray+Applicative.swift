// DeferredStreamTArray: outer = DeferredStream, inner = Array
// Type: DeferredStream<[A]>

public func liftA2TDeferredStreamArray<A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredStream<[A]>, DeferredStream<[B]>) -> DeferredStream<[C]> {
    { @Sendable sa, sb in
        liftA2DeferredStream({ arrA, arrB in
            arrA.flatMap { a in arrB.map { b in fn(a, b) } }
        })(sa, sb)
    }
}

public func applyTDeferredStreamArray<A: Sendable, B: Sendable>(
    _ fns: DeferredStream<[@Sendable (A) -> B]>,
    _ values: DeferredStream<[A]>
) -> DeferredStream<[B]> {
    liftA2DeferredStream({ arrF, arrA in
        arrF.flatMap { f in arrA.map { a in f(a) } }
    })(fns, values)
}
