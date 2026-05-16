#if canImport(Combine)
import Combine

// Boxes a non-Sendable Combine type for safe capture in @Sendable closures.
// PassthroughSubject and AnyPublisher are internally thread-safe but not marked Sendable.
private final class SendableBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}

/// Error surfaced by ``AnyPublisher/toDeferredTask()-failable`` when a failable publisher
/// completes successfully without emitting any value.
///
/// `Result<Output, Failure>` requires *some* failure to report when there is no `Output`
/// to deliver. Combine's `AsyncThrowingPublisher` surfaces nothing at all in that case —
/// it just stops iterating — so we synthesize this error to keep the bridge total and to
/// avoid hanging the awaiting task. Compare to the `Failure == Never` overload, which can
/// safely return `Output?` instead.
public struct EmptyPublisherError: Error, Sendable, Equatable {
    public init() {}
}

public extension DeferredTask {
    /// Convert a single-value `DeferredTask` into a Combine publisher that emits the
    /// computed value once, then completes.
    ///
    /// Uses a `PassthroughSubject` (not `Future`) so that downstream cancellation
    /// propagates: `handleEvents(receiveCancel:)` cancels the wrapping `Task`, and the
    /// `Task` checks `isCancelled` before forwarding the value into the subject.
    ///
    /// Each subscription triggers an independent execution of the underlying work.
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
    /// Collect the first emitted value of an infallible publisher into a `DeferredTask`.
    ///
    /// Returns `nil` if the publisher completes without emitting. An explicit `return`
    /// inside `for await` deallocates the iterator on exit, immediately cancelling the
    /// underlying Combine subscription so later values are never produced.
    ///
    /// For the failable counterpart see ``toDeferredTask()-failable``, which surfaces
    /// the empty-completion case as ``EmptyPublisherError``.
    func toDeferredTask() -> DeferredTask<Output?> {
        let box = SendableBox(self)
        return DeferredTask {
            for await value in box.value.values { return value }
            return nil
        }
    }

    /// Collect every value emitted by an infallible publisher into a `DeferredTask<[Output]>`.
    ///
    /// The task completes only when the publisher itself completes; an empty publisher
    /// resolves to `[]`.
    func toDeferredTaskArray() -> DeferredTask<[Output]> {
        let box = SendableBox(self)
        return DeferredTask {
            var results: [Output] = []
            for await value in box.value.values { results.append(value) }
            return results
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension AnyPublisher where Output: Sendable, Failure: Error & Sendable {
    /// Collect the first outcome of a failable publisher into a
    /// `DeferredTask<Result<Output, any Error>>`.
    ///
    /// Three completion paths, each mapped to a `Result`:
    ///
    /// | Publisher behaviour                         | Result                          |
    /// |---------------------------------------------|---------------------------------|
    /// | Emits a value                               | `.success(value)`               |
    /// | Fails with `Failure`                        | `.failure(Failure)` as `any Error` |
    /// | Completes with no value                     | `.failure(EmptyPublisherError())`  |
    ///
    /// The failure type widens to `any Error` so the bridge can synthesize
    /// ``EmptyPublisherError`` for the no-emit completion path — callers needing the
    /// original `Failure` back can downcast with `as?` inside `.mapError`.
    ///
    /// Returning on the first value deallocates the underlying async iterator, which
    /// cancels the upstream Combine subscription, so any subsequent values or failures
    /// are never produced.
    func toDeferredTask() -> DeferredTask<Result<Output, any Error>> {
        let box = SendableBox(self)
        return DeferredTask {
            do {
                for try await value in box.value.values {
                    return .success(value)
                }
                return .failure(EmptyPublisherError())
            } catch {
                return .failure(error)
            }
        }
    }
}

#endif
