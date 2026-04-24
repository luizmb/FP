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
        var cancellables = Set<AnyCancellable>()
        nonisolated(unsafe) var received: [Int] = []
        nonisolated(unsafe) var completions = 0

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let pub = task.toPublisher()
            func onComplete() { completions += 1; if completions == 2 { continuation.resume() } }
            pub.sink(receiveCompletion: { _ in onComplete() }, receiveValue: { received.append($0) }).store(in: &cancellables)
            pub.sink(receiveCompletion: { _ in onComplete() }, receiveValue: { received.append($0) }).store(in: &cancellables)
        }

        #expect(received.sorted() == [1, 2])
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
