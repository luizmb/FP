// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct AsyncSequenceTests {
    // MARK: - Functor Tests (Core Methods)

    @Test func fmap() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        let doubled = sequence.map { $0 * 2 }

        var results: [Int] = []
        for try await value in doubled {
            results.append(value)
        }

        #expect(results == [2, 4, 6])
    }

    @Test func curriedFmap() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        let toString = AsyncStream<Int>.fmap { (value: Int) async -> String in "\(value)" }
        let mapped = toString(sequence)

        var results: [String] = []
        for try await value in mapped {
            results.append(value)
        }

        #expect(results == ["1", "2"])
    }

    // MARK: - Applicative Tests (Core Methods)

    @Test func zip() async throws {
        let sequence1 = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        let sequence2 = AsyncStream<String> { continuation in
            continuation.yield("a")
            continuation.yield("b")
            continuation.finish()
        }

        let zipped = AsyncStream<Int>.zip(sequence1, sequence2)

        var results: [(Int, String)] = []
        for try await value in zipped {
            results.append(value)
        }

        #expect(results.count == 2)
        #expect(results[0].0 == 1)
        #expect(results[0].1 == "a")
        #expect(results[1].0 == 2)
        #expect(results[1].1 == "b")
    }

    // MARK: - Monad Tests (Core Methods)

    @Test func bind() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        let bound = sequence.bind { value in
            AsyncStream<Int> { continuation in
                continuation.yield(value)
                continuation.yield(value * 10)
                continuation.finish()
            }
        }

        var results: [Int] = []
        for try await value in bound {
            results.append(value)
        }

        #expect(results == [1, 10, 2, 20])
    }

    // MARK: - seqLeft

    @Test func seqLeftKeepsLeftValuesAndPullsLeftFirst() async {
        let log = PullLog()
        let result = AsyncStream<Int>.seqLeft(loggedStream("l", [1, 2], log), loggedStream("r", [10, 20], log))

        var values: [Int] = []
        for await value in result {
            values.append(value)
        }

        #expect(values == [1, 2])
        #expect(await Array(log.entries.prefix(4)) == ["l", "r", "l", "r"])
    }
}

private actor PullLog {
    private(set) var entries: [String] = []
    func record(_ entry: String) { entries.append(entry) }
}

private func loggedStream(_ label: String, _ values: [Int], _ log: PullLog) -> AsyncStream<Int> {
    let box = UnfoldCursor(values)
    return AsyncStream(unfolding: {
        await log.record(label)
        return await box.next()
    })
}

private actor UnfoldCursor {
    private var remaining: [Int]
    init(_ values: [Int]) { remaining = values }
    func next() -> Int? { remaining.isEmpty ? nil : remaining.removeFirst() }
}
