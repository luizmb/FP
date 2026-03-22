public extension DeferredStream {
    // fmap :: (a -> b) -> DeferredStream a -> DeferredStream b
    func fmap<B: Sendable>(_ fn: @escaping @Sendable (Element) -> B) -> DeferredStream<B> {
        let outer = self
        return DeferredStream<B> {
            AsyncStream<B> { continuation in
                let task = Task { @Sendable in
                    for await element in outer {
                        continuation.yield(fn(element))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    static func fmap<B: Sendable>(
        _ fn: @escaping @Sendable (Element) -> B
    ) -> @Sendable (DeferredStream<Element>) -> DeferredStream<B> {
        { @Sendable stream in stream.fmap(fn) }
    }

    // replace :: DeferredStream a -> b -> DeferredStream b
    func replace<B: Sendable>(_ value: B) -> DeferredStream<B> {
        fmap(const(value))
    }
}
