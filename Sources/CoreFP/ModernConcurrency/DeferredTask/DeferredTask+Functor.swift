public extension DeferredTask {
    // fmap :: (a -> b) -> DeferredTask a -> DeferredTask b
    func map<B: Sendable>(_ fn: @escaping @Sendable (Success) -> B) -> DeferredTask<B> {
        DeferredTask<B> { await fn(self.run()) }
    }

    static func fmap<B: Sendable>(
        _ fn: @escaping @Sendable (Success) -> B
    ) -> @Sendable (DeferredTask<Success>) -> DeferredTask<B> {
        { @Sendable task in task.map(fn) }
    }

    // replace :: DeferredTask a -> b -> DeferredTask b
    func replace<B: Sendable>(_ value: B) -> DeferredTask<B> {
        map(const(value))
    }
}
