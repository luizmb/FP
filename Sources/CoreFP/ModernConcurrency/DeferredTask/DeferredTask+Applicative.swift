public extension DeferredTask {
    // pure :: a -> DeferredTask a
    static func pure(_ value: Success) -> DeferredTask<Success> {
        DeferredTask { value }
    }

    // seqRight :: DeferredTask a -> DeferredTask b -> DeferredTask b
    func seqRight<B: Sendable>(_ rhs: DeferredTask<B>) -> DeferredTask<B> {
        liftA2DeferredTask({ _, b in b })(self, rhs)
    }

    // seqLeft :: DeferredTask a -> DeferredTask b -> DeferredTask a
    func seqLeft<B: Sendable>(_ rhs: DeferredTask<B>) -> DeferredTask<Success> {
        liftA2DeferredTask({ a, _ in a })(self, rhs)
    }

    // zip :: DeferredTask a -> DeferredTask b -> … -> DeferredTask (a, b, …)
    // Runs tasks sequentially left-to-right, collecting results into a tuple.
    static func zip<B: Sendable, each C: Sendable>(
        _ first: DeferredTask<Success>,
        _ second: DeferredTask<B>,
        _ additional: repeat DeferredTask<each C>
    ) -> DeferredTask<(Success, B, repeat each C)> {
        DeferredTask<(Success, B, repeat each C)> {
            (await first.run(), await second.run(), repeat await (each additional).run())
        }
    }
}

// apply :: DeferredTask (a -> b) -> DeferredTask a -> DeferredTask b
// Sequential (lawful): equivalent to fns >>= { f in values >>= { a in pure(f(a)) } }
public func applyDeferredTask<A: Sendable, B: Sendable>(
    _ fns: DeferredTask<@Sendable (A) -> B>,
    _ values: DeferredTask<A>
) -> DeferredTask<B> {
    DeferredTask<B> {
        let f = await fns.run()
        let a = await values.run()
        return f(a)
    }
}

// liftA2 :: (a -> b -> c) -> DeferredTask a -> DeferredTask b -> DeferredTask c
public func liftA2DeferredTask<A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredTask<A>, DeferredTask<B>) -> DeferredTask<C> {
    { @Sendable ta, tb in
        DeferredTask<C> {
            let a = await ta.run()
            let b = await tb.run()
            return fn(a, b)
        }
    }
}
