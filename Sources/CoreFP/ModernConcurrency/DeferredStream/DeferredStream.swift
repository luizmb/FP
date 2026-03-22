// DeferredStream<Element>: a lazy AsyncSequence whose producer starts only at first iteration.
// Contrast with AsyncStream: its body/Task runs at init time.
// DeferredStream defers the factory call to makeAsyncIterator().

public struct DeferredStream<Element: Sendable>: AsyncSequence, Sendable {
    public typealias AsyncIterator = AsyncStream<Element>.AsyncIterator

    let factory: @Sendable () -> AsyncStream<Element>

    public init(_ factory: @escaping @Sendable () -> AsyncStream<Element>) {
        self.factory = factory
    }

    public func makeAsyncIterator() -> AsyncIterator {
        factory().makeAsyncIterator()
    }
}

public extension DeferredStream {
    /// Wrap an existing eager AsyncStream (the stream is already created; use only when you own it).
    static func wrap(_ stream: AsyncStream<Element>) -> DeferredStream<Element> {
        DeferredStream { stream }
    }
}
