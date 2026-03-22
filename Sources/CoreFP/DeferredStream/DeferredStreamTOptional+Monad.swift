// DeferredStreamTOptional: outer = DeferredStream, inner = Optional
// Type: DeferredStream<A?>

// flatMapT :: DeferredStream<A?> -> (A -> DeferredStream<B?>) -> DeferredStream<B?>
// nil elements pass through as nil; Some(a) is replaced by all elements of fn(a)
public func flatMapTDeferredStreamOptional<A: Sendable, B: Sendable>(
    _ stream: DeferredStream<A?>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<B?>
) -> DeferredStream<B?> {
    let s = stream
    return DeferredStream<B?> {
        AsyncStream<B?> { continuation in
            Task { @Sendable in
                for await optA in s {
                    if let a = optA {
                        for await optB in fn(a) {
                            continuation.yield(optB)
                        }
                    } else {
                        continuation.yield(.none)
                    }
                }
                continuation.finish()
            }
        }
    }
}

public func bindTDeferredStreamOptional<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<B?>
) -> @Sendable (DeferredStream<A?>) -> DeferredStream<B?> {
    { @Sendable stream in flatMapTDeferredStreamOptional(stream, fn) }
}
