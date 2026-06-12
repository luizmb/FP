// DeferredStream<Element>: a lazy AsyncSequence whose producer starts only at first iteration.
// Contrast with AsyncStream: its body/Task runs at init time.
// DeferredStream defers the factory call to makeAsyncIterator().

/// A lazy `AsyncSequence` whose producer is created only when iteration begins.
///
/// Unlike `AsyncStream`, whose body closure runs at initialisation time, `DeferredStream`
/// defers the factory call to `makeAsyncIterator()`. This means:
///
/// - No work is done until a `for await` loop begins.
/// - Each new iterator (each `for await` loop) calls the factory again, creating a fresh
///   `AsyncStream` — enabling true restartable or re-subscribable streams.
///
/// `DeferredStream` is the Swift async/await counterpart to Combine's `Deferred<P>`.
/// It is a full ``Functor``, ``Applicative``, and ``Monad`` — operator forms available in
/// `CoreFPOperators`.
///
/// ## Creating a DeferredStream
///
/// ```swift
/// // Lazy: the body closure does not execute until iteration starts.
/// let stream = DeferredStream {
///     AsyncStream<Int> { continuation in
///         Task {
///             for i in 0..<5 {
///                 continuation.yield(i)
///             }
///             continuation.finish()
///         }
///     }
/// }
///
/// // Wrapping an already-created stream (use with care — iteration starts immediately
/// // on the wrapped stream the first time, not on each new iterator):
/// let wrapped = DeferredStream.wrap(existingStream)
/// ```
///
/// ## Functor / Monad operations
///
/// ```swift
/// let doubled = stream.map { $0 * 2 }          // DeferredStream<Int>
/// let filtered = stream.flatMap { n in          // DeferredStream<String>
///     DeferredStream { AsyncStream.just("\(n)") }
/// }
/// ```
///
/// - SeeAlso: ``DeferredTask``, `AsyncStream`
public struct DeferredStream<Element: Sendable>: AsyncSequence, Sendable {
    public typealias AsyncIterator = AsyncStream<Element>.AsyncIterator

    public let factory: @Sendable () -> AsyncStream<Element>

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
