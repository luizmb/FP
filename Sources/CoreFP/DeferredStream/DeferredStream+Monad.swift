public extension DeferredStream {
    // bind / flatMap :: DeferredStream a -> (a -> DeferredStream b) -> DeferredStream b
    // concatMap: sequential, lawful
    func flatMap<B: Sendable>(_ fn: @escaping @Sendable (Element) -> DeferredStream<B>) -> DeferredStream<B> {
        let outer = self
        return DeferredStream<B> {
            AsyncStream<B> { continuation in
                Task { @Sendable in
                    for await element in outer {
                        for await b in fn(element) {
                            continuation.yield(b)
                        }
                    }
                    continuation.finish()
                }
            }
        }
    }

    static func flatMap<B: Sendable>(
        _ fn: @escaping @Sendable (Element) -> DeferredStream<B>
    ) -> @Sendable (DeferredStream<Element>) -> DeferredStream<B> {
        { @Sendable stream in stream.flatMap(fn) }
    }

    // join :: DeferredStream (DeferredStream a) -> DeferredStream a
    static func join<A: Sendable>(_ nested: DeferredStream<DeferredStream<A>>) -> DeferredStream<A>
    where Element == DeferredStream<A> {
        nested.flatMap(id)
    }

    // kleisli :: (a -> DeferredStream b) -> (b -> DeferredStream c) -> (a -> DeferredStream c)
    static func kleisli<B: Sendable, C: Sendable>(
        _ f: @escaping @Sendable (Element) -> DeferredStream<B>,
        _ g: @escaping @Sendable (B) -> DeferredStream<C>
    ) -> @Sendable (Element) -> DeferredStream<C> {
        { @Sendable a in f(a).flatMap(g) }
    }
}
