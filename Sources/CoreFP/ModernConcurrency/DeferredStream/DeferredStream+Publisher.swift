#if canImport(Combine)
import Combine

// Boxes a non-Sendable Combine type for safe capture in @Sendable closures.
// PassthroughSubject and AnyPublisher are internally thread-safe but not marked Sendable.
private final class SendableBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}

public extension DeferredStream {
    // Convert a lazy async stream to a publisher.
    // The underlying stream factory — and therefore the Task — starts only on subscription.
    //
    // Cancellation: task.cancel() alone cannot wake a Task suspended waiting on an AsyncStream
    // that has not yielded (AsyncStream.next() doesn't cooperate with Task cancellation).
    // withTaskCancellationHandler forces the subject to complete immediately on cancel,
    // unblocking any downstream subscribers regardless of stream state.
    func toPublisher() -> AnyPublisher<Element, Never> {
        Deferred { [self] () -> AnyPublisher<Element, Never> in
            let box = SendableBox(PassthroughSubject<Element, Never>())
            let task = Task {
                await withTaskCancellationHandler {
                    for await element in self { box.value.send(element) }
                    box.value.send(completion: .finished)
                } onCancel: {
                    // Fires synchronously when task.cancel() is called.
                    // PassthroughSubject ignores duplicate completions, so this is safe
                    // even if the loop already finished and sent .finished naturally.
                    box.value.send(completion: .finished)
                }
            }
            return box.value
                .handleEvents(receiveCancel: { task.cancel() })
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension AnyPublisher where Failure == Never, Output: Sendable {
    // Wrap a publisher in a DeferredStream.
    // The publisher is subscribed on first iteration of the stream.
    // defer ensures continuation.finish() is always called — even if the loop
    // exits early via Task cancellation — so consumers never hang waiting for the next element.
    func toDeferredStream() -> DeferredStream<Output> {
        let box = SendableBox(self)
        return DeferredStream {
            AsyncStream { continuation in
                let task = Task {
                    defer { continuation.finish() }
                    for await value in box.value.values {
                        if Task.isCancelled { break }
                        continuation.yield(value)
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }
}

#endif
