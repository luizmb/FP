import XCTest
@testable import FP
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AsyncSequenceTests: XCTestCase {

    // MARK: - Functor Tests (Core Methods)

    func testFmap() async throws {
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

    func testCurriedFmap() async throws {
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

        XCTAssertEqual(results, ["1", "2"])
    }

    // MARK: - Applicative Tests (Core Methods)

    func testZip() async throws {
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

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].0, 1)
        XCTAssertEqual(results[0].1, "a")
        XCTAssertEqual(results[1].0, 2)
        XCTAssertEqual(results[1].1, "b")
    }

    // MARK: - Monad Tests (Core Methods)

    func testBind() async throws {
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

        XCTAssertEqual(results, [1, 10, 2, 20])
    }

}

