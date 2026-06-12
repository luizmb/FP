public extension DeferredStream {
    // pure :: a -> DeferredStream a
    static func pure(_ value: Element) -> DeferredStream<Element> {
        DeferredStream { AsyncStream { continuation in
            continuation.yield(value)
            continuation.finish()
        }
        }
    }

    // seqRight :: DeferredStream a -> DeferredStream b -> DeferredStream b
    func seqRight<B: Sendable>(_ rhs: DeferredStream<B>) -> DeferredStream<B> {
        liftA2DeferredStream({ _, b in b })(self, rhs)
    }

    // seqLeft :: DeferredStream a -> DeferredStream b -> DeferredStream a
    func seqLeft<B: Sendable>(_ rhs: DeferredStream<B>) -> DeferredStream<Element> {
        liftA2DeferredStream({ a, _ in a })(self, rhs)
    }

    // zip :: DeferredStream a -> DeferredStream b -> DeferredStream (a, b)
    // Pairs elements positionally; stops when either stream ends.
    static func zip<B: Sendable>(
        _ sa: DeferredStream<Element>,
        _ sb: DeferredStream<B>
    ) -> DeferredStream<(Element, B)> {
        DeferredStream<(Element, B)> {
            let streamA = sa.factory()
            let streamB = sb.factory()
            return AsyncStream<(Element, B)> { continuation in
                let task = Task { @Sendable in
                    var ia = streamA.makeAsyncIterator()
                    var ib = streamB.makeAsyncIterator()
                    while let a = await ia.next(), let b = await ib.next() {
                        continuation.yield((a, b))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    // zip3 :: DeferredStream a -> DeferredStream b -> DeferredStream c -> DeferredStream (a, b, c)
    // Pairs elements positionally; stops when any stream ends.
    static func zip3<B: Sendable, C: Sendable>(
        _ sa: DeferredStream<Element>,
        _ sb: DeferredStream<B>,
        _ sc: DeferredStream<C>
    ) -> DeferredStream<(Element, B, C)> {
        DeferredStream<(Element, B, C)> {
            let streamA = sa.factory()
            let streamB = sb.factory()
            let streamC = sc.factory()
            return AsyncStream<(Element, B, C)> { continuation in
                let task = Task { @Sendable in
                    var ia = streamA.makeAsyncIterator()
                    var ib = streamB.makeAsyncIterator()
                    var ic = streamC.makeAsyncIterator()
                    while let a = await ia.next(), let b = await ib.next(), let c = await ic.next() {
                        continuation.yield((a, b, c))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    // zip4 :: DeferredStream a -> … -> DeferredStream d -> DeferredStream (a, b, c, d)
    // Pairs elements positionally; stops when any stream ends.
    static func zip4<B: Sendable, C: Sendable, D: Sendable>(
        _ sa: DeferredStream<Element>,
        _ sb: DeferredStream<B>,
        _ sc: DeferredStream<C>,
        _ sd: DeferredStream<D>
    ) -> DeferredStream<(Element, B, C, D)> {
        DeferredStream<(Element, B, C, D)> {
            let streamA = sa.factory()
            let streamB = sb.factory()
            let streamC = sc.factory()
            let streamD = sd.factory()
            return AsyncStream<(Element, B, C, D)> { continuation in
                let task = Task { @Sendable in
                    var ia = streamA.makeAsyncIterator()
                    var ib = streamB.makeAsyncIterator()
                    var ic = streamC.makeAsyncIterator()
                    var id = streamD.makeAsyncIterator()
                    while let a = await ia.next(), let b = await ib.next(),
                          let c = await ic.next(), let d = await id.next() {
                        continuation.yield((a, b, c, d))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }
}

// apply :: DeferredStream (a -> b) -> DeferredStream a -> DeferredStream b
// Zip-based: pairs each fn with each value positionally
public func applyDeferredStream<A: Sendable, B: Sendable>(
    _ fns: DeferredStream<@Sendable (A) -> B>,
    _ values: DeferredStream<A>
) -> DeferredStream<B> {
    DeferredStream<B> {
        let fnStream = fns.factory()
        let valStream = values.factory()
        return AsyncStream<B> { continuation in
            let task = Task { @Sendable in
                var fnIter = fnStream.makeAsyncIterator()
                var valIter = valStream.makeAsyncIterator()
                while let fn = await fnIter.next(), let val = await valIter.next() {
                    continuation.yield(fn(val))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// liftA2 :: (a -> b -> c) -> DeferredStream a -> DeferredStream b -> DeferredStream c
public func liftA2DeferredStream<A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredStream<A>, DeferredStream<B>) -> DeferredStream<C> {
    { @Sendable sa, sb in
        DeferredStream<C> {
            let streamA = sa.factory()
            let streamB = sb.factory()
            return AsyncStream<C> { continuation in
                let task = Task { @Sendable in
                    var ia = streamA.makeAsyncIterator()
                    var ib = streamB.makeAsyncIterator()
                    while let a = await ia.next(), let b = await ib.next() {
                        continuation.yield(fn(a, b))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }
}
