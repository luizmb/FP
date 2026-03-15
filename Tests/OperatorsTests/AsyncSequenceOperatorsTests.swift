import XCTest
@testable import FP
@testable import Operators
import Operators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AsyncSequenceTests: XCTestCase {

    // MARK: - Functor Tests

    func testAsyncSequenceFmap() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        let doubled = sequence.fmap { $0 * 2 }
        var results: [Int] = []

        for try await value in doubled {
            results.append(value)
        }

        XCTAssertEqual(results, [2, 4, 6])
    }

    func testAsyncStreamFmapCurried() async throws {
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

        XCTAssertEqual(results, [2, 4, 6])
    }

    func testFunctorOperators() async throws {
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
        XCTAssertEqual(results, [2, 4])
    }

    func testMapReplace() async throws {
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
        XCTAssertEqual(results, [99, 99])
    }

    // MARK: - Monad Tests

    func testAsyncSequenceBind() async throws {
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

        XCTAssertEqual(results, [1, 10, 2, 20])
    }

    func testMonadBindOperator() async throws {
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
        XCTAssertEqual(results, [2, 4])
    }

    func testFlippedFmapOperator() async throws {
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
        XCTAssertEqual(results, [2, 4])
    }

    // MARK: - Applicative Tests

    func testLiftA2() async throws {
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
        XCTAssertEqual(results, [11, 22])
    }

    func testZip() async throws {
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

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].0, 1)
        XCTAssertEqual(results[0].1, "a")
        XCTAssertEqual(results[1].0, 2)
        XCTAssertEqual(results[1].1, "b")
    }

    func testApply() async throws {
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
        XCTAssertEqual(results, [10, 13])
    }
}
