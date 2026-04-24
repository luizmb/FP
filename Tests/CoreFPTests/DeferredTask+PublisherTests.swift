#if canImport(Combine)
import Combine
import CoreFP
import Testing

@Suite struct DeferredTaskPublisherTests {
    // MARK: - DeferredTask -> Publisher

    @Test func toPublisherEmitsSingleValue() async {
        let task = DeferredTask<Int> { 42 }
        var received: [Int] = []
        var cancellables = Set<AnyCancellable>()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            task.toPublisher()
                .sink(
                    receiveCompletion: { _ in continuation.resume() },
                    receiveValue: { received.append($0) }
                )
                .store(in: &cancellables)
        }

        #expect(received == [42])
    }

    @Test func toPublisherIsDeferred() async {
        nonisolated(unsafe) var ran = false
        let task = DeferredTask<Int> { ran = true; return 1 }
        let publisher = task.toPublisher()
        #expect(!ran, "task must not run before subscription")
        var cancellables = Set<AnyCancellable>()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            publisher.sink(
                receiveCompletion: { _ in continuation.resume() },
                receiveValue: { _ in }
            ).store(in: &cancellables)
        }
        #expect(ran)
    }

    @Test func toPublisherEachSubscriberGetsOwnExecution() async {
        nonisolated(unsafe) var executionCount = 0
        let task = DeferredTask<Int> { executionCount += 1; return executionCount }
        let pub = task.toPublisher()
        var cancellables = Set<AnyCancellable>()
        nonisolated(unsafe) var received: [Int] = []

        // Run subscriptions sequentially to avoid a data race on executionCount.
        // The goal is to verify each subscription triggers an independent task run.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            pub.sink(receiveCompletion: { _ in continuation.resume() }, receiveValue: { received.append($0) }).store(in: &cancellables)
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            pub.sink(receiveCompletion: { _ in continuation.resume() }, receiveValue: { received.append($0) }).store(in: &cancellables)
        }

        #expect(received == [1, 2])
    }

    // MARK: - Publisher -> DeferredTask

    @Test func toDeferredTaskReturnsFirstValue() async {
        let publisher = [10, 20, 30].publisher.eraseToAnyPublisher()
        let result = await publisher.toDeferredTask().run()
        #expect(result == 10)
    }

    @Test func toDeferredTaskReturnsNilOnEmpty() async {
        let publisher = Empty<Int, Never>().eraseToAnyPublisher()
        let result = await publisher.toDeferredTask().run()
        #expect(result == nil)
    }

    @Test func toDeferredTaskArrayCollectsAll() async {
        let publisher = [1, 2, 3].publisher.eraseToAnyPublisher()
        let result = await publisher.toDeferredTaskArray().run()
        #expect(result == [1, 2, 3])
    }

    @Test func toDeferredTaskArrayReturnsEmptyForEmptyPublisher() async {
        let publisher = Empty<Int, Never>().eraseToAnyPublisher()
        let result = await publisher.toDeferredTaskArray().run()
        #expect(result == [])
    }
}

#endif
