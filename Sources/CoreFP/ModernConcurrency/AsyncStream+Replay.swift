// SPDX-License-Identifier: Apache-2.0
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream where Element: Sendable {
    /// Turns a single-pass stream into a re-creatable source of streams.
    ///
    /// An `AsyncStream` can be iterated only once, but the list-like applicative (`ap`) needs to
    /// traverse its argument once per function. `replayable` makes that possible without dropping
    /// or reordering anything: the first returned stream that is iterated drains the upstream once,
    /// buffering every element in memory, and every returned stream (that first one included)
    /// replays the whole buffer in upstream order.
    ///
    /// - The upstream is untouched until one of the returned streams is iterated, and runs at most once.
    /// - Each replayed stream starts yielding only after the upstream has finished, so an infinite
    ///   upstream never yields anything here.
    /// - Cancelling a replayed stream while it waits cancels the drain.
    ///
    /// ```swift
    /// let source = AsyncStream<Int>.replayable(numbers)   // numbers: 1, 2
    /// source()   // 1, 2  (drains `numbers`)
    /// source()   // 1, 2  (replays the buffer)
    /// ```
    static func replayable(_ stream: AsyncStream<Element>) -> @Sendable () -> AsyncStream<Element> {
        let buffer = ReplayBuffer(stream)
        return {
            AsyncStream { continuation in
                let task = Task { @Sendable in
                    for element in await buffer.elements() {
                        continuation.yield(element)
                    }
                    continuation.finish()
                }
                // swiftlint:disable:next closure_ignoring_args
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }
}

/// Drains an upstream once and memoises its elements.
///
/// The drain runs in a single stored `Task`, so concurrent callers share it instead of iterating
/// the single-pass upstream twice. Cancellation of any waiting caller is forwarded to the drain.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private actor ReplayBuffer<Element: Sendable> {
    private let upstream: AsyncStream<Element>
    private var drain: Task<[Element], Never>?

    init(_ upstream: AsyncStream<Element>) {
        self.upstream = upstream
    }

    func elements() async -> [Element] {
        let task = drain ?? Task { [upstream] in await upstream.reduce(into: []) { $0.append($1) } }
        drain = task
        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
package extension AsyncStream where Element: Sendable {
    /// Ordered concat (`>>=` of the stream monad), closed over `AsyncStream`.
    ///
    /// Each inner stream runs to completion, in upstream order, before the next upstream element is pulled.
    package static func concatMap<A: Sendable>(
        _ stream: AsyncStream<A>,
        _ fn: @escaping @Sendable (A) -> AsyncStream<Element>
    ) -> AsyncStream<Element> {
        AsyncStream { continuation in
            let task = Task { @Sendable in
                for await a in stream {
                    for await element in fn(a) {
                        continuation.yield(element)
                    }
                }
                continuation.finish()
            }
            // swiftlint:disable:next closure_ignoring_args
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// `fmap` closed over `AsyncStream`.
    package static func mapStream<A: Sendable>(
        _ stream: AsyncStream<A>,
        _ fn: @escaping @Sendable (A) -> Element
    ) -> AsyncStream<Element> {
        AsyncStream { continuation in
            let task = Task { @Sendable in
                for await a in stream {
                    continuation.yield(fn(a))
                }
                continuation.finish()
            }
            // swiftlint:disable:next closure_ignoring_args
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// `pure` closed over `AsyncStream`: a stream that yields `value` once and finishes.
    package static func just(_ value: Element) -> AsyncStream<Element> {
        AsyncStream { continuation in
            continuation.yield(value)
            continuation.finish()
        }
    }
}
