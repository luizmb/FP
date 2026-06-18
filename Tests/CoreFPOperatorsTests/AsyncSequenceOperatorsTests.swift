// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Testing
@Suite struct AsyncSequenceTests {
    // MARK: - Functor Tests

    @Test func asyncSequenceFmap() async throws {
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

    @Test func asyncStreamFmapCurried() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let fmap = AsyncStream<Int>.fmap(double)
        let doubled = fmap(sequence)

        var results: [Int] = []
        for await value in doubled {
            results.append(value)
        }

        #expect(results == [2, 4, 6])
    }

    @Test func functorOperators() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        // Test <£> operator
        let doubled = { $0 * 2 } <£> sequence
        var results: [Int] = []
        for try await value in doubled {
            results.append(value)
        }
        #expect(results == [2, 4])
    }

    @Test func mapReplace() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        // Test £> operator
        let replaced = sequence £> 99
        var results: [Int] = []
        for try await value in replaced {
            results.append(value)
        }
        #expect(results == [99, 99])
    }

    // MARK: - Monad Tests

    @Test func asyncSequenceBind() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        let expanded = sequence.bind { value in
            AsyncStream<Int> { continuation in
                continuation.yield(value)
                continuation.yield(value * 10)
                continuation.finish()
            }
        }

        var results: [Int] = []
        for try await value in expanded {
            results.append(value)
        }

        #expect(results == [1, 10, 2, 20])
    }

    @Test func monadBindOperator() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        // Test >>- operator
        let expanded = sequence >>- { value in
            AsyncStream<Int> { continuation in
                continuation.yield(value * 2)
                continuation.finish()
            }
        }

        var results: [Int] = []
        for try await value in expanded {
            results.append(value)
        }
        #expect(results == [2, 4])
    }

    @Test func flippedFmapOperator() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        // Test <&> operator
        let doubled = sequence <&> { $0 * 2 }
        var results: [Int] = []
        for try await value in doubled {
            results.append(value)
        }
        #expect(results == [2, 4])
    }

    // MARK: - Applicative Tests

    @Test func liftA2() async throws {
        let stream1 = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        let stream2 = AsyncStream<Int> { continuation in
            continuation.yield(10)
            continuation.yield(20)
            continuation.finish()
        }

        let liftedAdd = AsyncStream<Int>.liftA2 { (a: Int, b: Int) -> Int in a + b }
        let result = liftedAdd(stream1, stream2)

        var results: [Int] = []
        for await value in result {
            results.append(value)
        }
        #expect(results == [11, 22])
    }

    @Test func zip() async throws {
        let stream1 = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        let stream2 = AsyncStream<String> { continuation in
            continuation.yield("a")
            continuation.yield("b")
            continuation.finish()
        }

        let zipped = AsyncStream<(Int, String)>.zip(stream1, stream2)
        var results: [(Int, String)] = []
        for await pair in zipped {
            results.append(pair)
        }

        #expect(results.count == 2)
        #expect(results[0].0 == 1)
        #expect(results[0].1 == "a")
        #expect(results[1].0 == 2)
        #expect(results[1].1 == "b")
    }

    @Test func apply() async throws {
        let functions = AsyncStream<@Sendable (Int) -> Int> { continuation in
            let double: @Sendable (Int) -> Int = { $0 * 2 }
            let addTen: @Sendable (Int) -> Int = { $0 + 10 }
            continuation.yield(double)
            continuation.yield(addTen)
            continuation.finish()
        }

        let values = AsyncStream<Int> { continuation in
            continuation.yield(5)
            continuation.yield(3)
            continuation.finish()
        }

        let result = AsyncStream<Int>.apply(functions, values)
        var results: [Int] = []
        for await value in result {
            results.append(value)
        }
        #expect(results == [10, 13])
    }
}
