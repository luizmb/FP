public extension DeferredStream {
    // fmap :: (a -> b) -> DeferredStream a -> DeferredStream b
    func map<B: Sendable>(_ fn: @escaping @Sendable (Element) -> B) -> DeferredStream<B> {
        let outerFactory = self.factory
        return DeferredStream<B> {
            let upstream = outerFactory()
            return AsyncStream<B> { continuation in
                let task = Task { @Sendable in
                    for await element in upstream {
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
        { @Sendable stream in stream.map(fn) }
    }

    // replace :: DeferredStream a -> b -> DeferredStream b
    func replace<B: Sendable>(_ value: B) -> DeferredStream<B> {
        map(const(value))
    }
}
