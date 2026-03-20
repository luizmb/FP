import XCTest
@testable import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AsyncThrowingStreamResultTests: XCTestCase {

    struct TestError: Error, Equatable {
        let message: String
        static let fail = TestError(message: "fail")
    }

    // MARK: - toResultStream

    func testToResultStreamAllElements() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        var results: [Result<Int, any Error>] = []
        for await value in stream.toResultStream() {
            results.append(value)
        }

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(try? results[0].get(), 1)
        XCTAssertEqual(try? results[1].get(), 2)
        XCTAssertEqual(try? results[2].get(), 3)
    }

    func testToResultStreamWithError() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(1)
            continuation.finish(throwing: TestError.fail)
        }

        var results: [Result<Int, any Error>] = []
        for await value in stream.toResultStream() {
            results.append(value)
        }

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(try? results[0].get(), 1)
        switch results[1] {
        case .failure(let error):
            XCTAssertEqual(error as? TestError, .fail)
        case .success:
            XCTFail("Expected .failure")
        }
    }

    func testToResultStreamEmpty() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.finish()
        }

        var results: [Result<Int, any Error>] = []
        for await value in stream.toResultStream() {
            results.append(value)
        }

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - toThrowingStream

    func testToThrowingStreamAllSuccesses() async throws {
        let stream = AsyncStream<Result<Int, TestError>> { continuation in
            continuation.yield(.success(1))
            continuation.yield(.success(2))
            continuation.yield(.success(3))
            continuation.finish()
        }

        var results: [Int] = []
        for try await value in stream.toThrowingStream() as AsyncThrowingStream<Int, any Error> {
            results.append(value)
        }

        XCTAssertEqual(results, [1, 2, 3])
    }

    func testToThrowingStreamFailureThrows() async {
        let stream = AsyncStream<Result<Int, TestError>> { continuation in
            continuation.yield(.success(1))
            continuation.yield(.failure(.fail))
            continuation.yield(.success(2)) // never reached
            continuation.finish()
        }

        var results: [Int] = []
        var caughtError: TestError?

        do {
            for try await value in stream.toThrowingStream() as AsyncThrowingStream<Int, any Error> {
                results.append(value)
            }
        } catch let error as TestError {
            caughtError = error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(results, [1])
        XCTAssertEqual(caughtError, .fail)
    }

    // MARK: - Round trip

    func testRoundTripThroughResultStream() async throws {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(10)
            continuation.yield(20)
            continuation.finish()
        }

        var results: [Int] = []
        for try await value in stream.toResultStream().toThrowingStream() as AsyncThrowingStream<Int, any Error> {
            results.append(value)
        }

        XCTAssertEqual(results, [10, 20])
    }

    func testRoundTripErrorThroughResultStream() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(10)
            continuation.finish(throwing: TestError.fail)
        }

        var results: [Int] = []
        var caughtError: TestError?

        do {
            for try await value in stream.toResultStream().toThrowingStream() as AsyncThrowingStream<Int, any Error> {
                results.append(value)
            }
        } catch let error as TestError {
            caughtError = error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(results, [10])
        XCTAssertEqual(caughtError, .fail)
    }
}
