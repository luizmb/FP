public extension DeferredStream {
    // bind / flatMap :: DeferredStream a -> (a -> DeferredStream b) -> DeferredStream b
    // concatMap: sequential, lawful
    func flatMap<B: Sendable>(_ fn: @escaping @Sendable (Element) -> DeferredStream<B>) -> DeferredStream<B> {
        let outerFactory = self.factory
        return DeferredStream<B> {
            let upstream = outerFactory()
            return AsyncStream<B> { continuation in
                let task = Task { @Sendable in
                    for await element in upstream {
                        for await b in fn(element) {
                            continuation.yield(b)
                        }
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    static func flatMap<B: Sendable>(
        _ fn: @escaping @Sendable (Element) -> DeferredStream<B>
    ) -> @Sendable (DeferredStream<Element>) -> DeferredStream<B> {
        { @Sendable stream in stream.flatMap(fn) }
    }

    // alt :: DeferredStream a -> DeferredStream a -> DeferredStream a
    // Concatenation: yield all elements from lhs, then all from rhs.
    static func alt(_ lhs: DeferredStream<Element>, _ rhs: @autoclosure () -> DeferredStream<Element>) -> DeferredStream<Element> {
        let lhsFactory = lhs.factory
        let rhsFactory = rhs().factory
        return DeferredStream<Element> {
            let lhsStream = lhsFactory()
            let rhsStream = rhsFactory()
            return AsyncStream<Element> { continuation in
                let task = Task { @Sendable in
                    for await element in lhsStream { continuation.yield(element) }
                    for await element in rhsStream { continuation.yield(element) }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    // join :: DeferredStream (DeferredStream a) -> DeferredStream a
    static func join<A: Sendable>(_ nested: DeferredStream<DeferredStream<A>>) -> DeferredStream<A>
    where Element == DeferredStream<A> {
        nested.flatMap(CoreFP.id)
    }

    // void :: DeferredStream a -> DeferredStream ()
    func void() -> DeferredStream<Void> {
        map(ignore)
    }

    // kleisli :: (a -> DeferredStream b) -> (b -> DeferredStream c) -> (a -> DeferredStream c)
    static func kleisli<B: Sendable, C: Sendable>(
        _ f: @escaping @Sendable (Element) -> DeferredStream<B>,
        _ g: @escaping @Sendable (B) -> DeferredStream<C>
    ) -> @Sendable (Element) -> DeferredStream<C> {
        { @Sendable a in f(a).flatMap(g) }
    }
}
