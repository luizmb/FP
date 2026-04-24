#if canImport(Combine)
import Combine
import CoreFP
import Testing

@Suite struct DeferredStreamPublisherTests {
    // MARK: - DeferredStream -> Publisher

    @Test func toPublisherEmitsAllElements() async {
        let stream = DeferredStream<Int> {
            AsyncStream { continuation in
                for i in 1...3 { continuation.yield(i) }
                continuation.finish()
            }
        }
        var received: [Int] = []
        var cancellables = Set<AnyCancellable>()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            stream.toPublisher()
                .sink(
                    receiveCompletion: { _ in continuation.resume() },
                    receiveValue: { received.append($0) }
                )
                .store(in: &cancellables)
        }

        #expect(received == [1, 2, 3])
    }

    @Test func toPublisherIsDeferred() async {
        nonisolated(unsafe) var factoryRan = false
        let stream = DeferredStream<Int> {
            factoryRan = true
            return AsyncStream { $0.finish() }
        }
        let publisher = stream.toPublisher()
        #expect(!factoryRan, "factory must not run before subscription")
        var cancellables = Set<AnyCancellable>()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            publisher.sink(
                receiveCompletion: { _ in continuation.resume() },
                receiveValue: { _ in }
            ).store(in: &cancellables)
        }
        #expect(factoryRan)
    }

    @Test func toPublisherCancellationStopsStream() async {
        nonisolated(unsafe) var emitted = 0
        let stream = DeferredStream<Int> {
            AsyncStream { continuation in
                Task {
                    for i in 1...100 {
                        try? await Task.sleep(nanoseconds: 1_000_000)
                        continuation.yield(i)
                    }
                    continuation.finish()
                }
            }
        }
        var cancellables = Set<AnyCancellable>()
        let pub = stream.toPublisher()
        pub.sink(
            receiveCompletion: { _ in },
            receiveValue: { emitted = $0 }
        ).store(in: &cancellables)

        try? await Task.sleep(nanoseconds: 5_000_000)
        cancellables.removeAll()   // cancel subscription

        let snapshot = emitted
        try? await Task.sleep(nanoseconds: 20_000_000)
        #expect(emitted == snapshot, "no more values should arrive after cancellation")
    }

    // MARK: - Publisher -> DeferredStream

    @Test func toDeferredStreamYieldsAllElements() async {
        let publisher = [4, 5, 6].publisher.eraseToAnyPublisher()
        let stream = publisher.toDeferredStream()
        var received: [Int] = []
        for await value in stream { received.append(value) }
        #expect(received == [4, 5, 6])
    }

    @Test func toDeferredStreamIsDeferred() async {
        nonisolated(unsafe) var subscribed = false
        let publisher = Deferred<AnyPublisher<Int, Never>> {
            subscribed = true
            return [1].publisher.eraseToAnyPublisher()
        }.eraseToAnyPublisher()

        let stream = publisher.toDeferredStream()
        #expect(!subscribed, "publisher must not be subscribed before iteration starts")
        var cancellables = Set<AnyCancellable>()
        _ = cancellables  // silence warning
        for await _ in stream { break }
        #expect(subscribed)
    }
}

#endif
