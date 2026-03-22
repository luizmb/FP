// DeferredStreamTArray: outer = DeferredStream, inner = Array
// Type: DeferredStream<[A]>

// flatMapT :: DeferredStream<[A]> -> (A -> DeferredStream<[B]>) -> DeferredStream<[B]>
// For each emitted [A], applies fn to each element and concatenates all [B] arrays.
public func flatMapTDeferredStreamArray<A: Sendable, B: Sendable>(
    _ stream: DeferredStream<[A]>,
    _ fn: @escaping @Sendable (A) -> DeferredStream<[B]>
) -> DeferredStream<[B]> {
    let s = stream
    return DeferredStream<[B]> {
        AsyncStream<[B]> { continuation in
            Task { @Sendable in
                for await arrA in s {
                    var result: [B] = []
                    for a in arrA {
                        for await arrB in fn(a) {
                            result.append(contentsOf: arrB)
                        }
                    }
                    continuation.yield(result)
                }
                continuation.finish()
            }
        }
    }
}

public func bindTDeferredStreamArray<A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> DeferredStream<[B]>
) -> @Sendable (DeferredStream<[A]>) -> DeferredStream<[B]> {
    { @Sendable stream in flatMapTDeferredStreamArray(stream, fn) }
}
