#if canImport(Combine)
import Combine

// Boxes a non-Sendable Combine type for safe capture in @Sendable closures.
// PassthroughSubject and AnyPublisher are internally thread-safe but not marked Sendable.
private final class SendableBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}

public extension DeferredTask {
    // Convert a single-value deferred task to a publisher that emits once then completes.
    // Uses PassthroughSubject (not Future) so that subscriber cancellation propagates:
    // handleEvents cancels the Task, and the Task checks isCancelled before sending.
    func toPublisher() -> AnyPublisher<Success, Never> {
        Deferred { [self] () -> AnyPublisher<Success, Never> in
            let box = SendableBox(PassthroughSubject<Success, Never>())
            let task = Task {
                let value = await run()
                guard !Task.isCancelled else { return }
                box.value.send(value)
                box.value.send(completion: .finished)
            }
            return box.value
                .handleEvents(receiveCancel: { task.cancel() })
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension AnyPublisher where Failure == Never, Output: Sendable {
    // Collect the first emitted value into a DeferredTask.
    // Returns nil if the publisher completes without emitting.
    // An explicit return inside for-await deallocates the iterator on exit,
    // immediately cancelling the underlying Combine subscription.
    func toDeferredTask() -> DeferredTask<Output?> {
        let box = SendableBox(self)
        return DeferredTask {
            for await value in box.value.values { return value }
            return nil
        }
    }

    // Collect all emitted values into a DeferredTask<[Output]>.
    func toDeferredTaskArray() -> DeferredTask<[Output]> {
        let box = SendableBox(self)
        return DeferredTask {
            var results: [Output] = []
            for await value in box.value.values { results.append(value) }
            return results
        }
    }
}

#endif
