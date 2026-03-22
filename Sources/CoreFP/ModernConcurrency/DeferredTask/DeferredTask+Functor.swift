public extension DeferredTask {
    // fmap :: (a -> b) -> DeferredTask a -> DeferredTask b
    func fmap<B: Sendable>(_ fn: @escaping @Sendable (Success) -> B) -> DeferredTask<B> {
        DeferredTask<B> { await fn(self.run()) }
    }

    static func fmap<B: Sendable>(
        _ fn: @escaping @Sendable (Success) -> B
    ) -> @Sendable (DeferredTask<Success>) -> DeferredTask<B> {
        { @Sendable task in task.fmap(fn) }
    }

    // replace :: DeferredTask a -> b -> DeferredTask b
    func replace<B: Sendable>(_ value: B) -> DeferredTask<B> {
        fmap(const(value))
    }
}
