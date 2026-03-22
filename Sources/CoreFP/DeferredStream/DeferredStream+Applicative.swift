public extension DeferredStream {
    // pure :: a -> DeferredStream a
    static func pure(_ value: Element) -> DeferredStream<Element> {
        DeferredStream { AsyncStream { continuation in
            continuation.yield(value)
            continuation.finish()
        }}
    }

    // seqRight :: DeferredStream a -> DeferredStream b -> DeferredStream b
    func seqRight<B: Sendable>(_ rhs: DeferredStream<B>) -> DeferredStream<B> {
        liftA2DeferredStream({ _, b in b })(self, rhs)
    }

    // seqLeft :: DeferredStream a -> DeferredStream b -> DeferredStream a
    func seqLeft<B: Sendable>(_ rhs: DeferredStream<B>) -> DeferredStream<Element> {
        liftA2DeferredStream({ a, _ in a })(self, rhs)
    }
}

// apply :: DeferredStream (a -> b) -> DeferredStream a -> DeferredStream b
// Zip-based: pairs each fn with each value positionally
public func applyDeferredStream<A: Sendable, B: Sendable>(
    _ fns: DeferredStream<@Sendable (A) -> B>,
    _ values: DeferredStream<A>
) -> DeferredStream<B> {
    DeferredStream<B> {
        AsyncStream<B> { continuation in
            Task { @Sendable in
                var fnIter = fns.makeAsyncIterator()
                var valIter = values.makeAsyncIterator()
                while let fn = await fnIter.next(), let val = await valIter.next() {
                    continuation.yield(fn(val))
                }
                continuation.finish()
            }
        }
    }
}

// liftA2 :: (a -> b -> c) -> DeferredStream a -> DeferredStream b -> DeferredStream c
public func liftA2DeferredStream<A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredStream<A>, DeferredStream<B>) -> DeferredStream<C> {
    { @Sendable sa, sb in
        DeferredStream<C> {
            AsyncStream<C> { continuation in
                Task { @Sendable in
                    var ia = sa.makeAsyncIterator()
                    var ib = sb.makeAsyncIterator()
                    while let a = await ia.next(), let b = await ib.next() {
                        continuation.yield(fn(a, b))
                    }
                    continuation.finish()
                }
            }
        }
    }
}
