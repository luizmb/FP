import XCTest
@testable import Either

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AsyncThrowingStreamEitherTests: XCTestCase {

    struct TestError: Error, Equatable {
        let message: String
        static let fail = TestError(message: "fail")
    }

    // MARK: - toEitherStream

    func testToEitherStreamAllElements() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        var results: [Either<any Error, Int>] = []
        for await value in stream.toEitherStream() {
            results.append(value)
        }

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].right, 1)
        XCTAssertEqual(results[1].right, 2)
        XCTAssertEqual(results[2].right, 3)
    }

    func testToEitherStreamWithError() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(1)
            continuation.finish(throwing: TestError.fail)
        }

        var results: [Either<any Error, Int>] = []
        for await value in stream.toEitherStream() {
            results.append(value)
        }

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].right, 1)
        guard case .left(let error) = results[1] else {
            XCTFail("Expected .left error")
            return
        }
        XCTAssertEqual(error as? TestError, .fail)
    }

    func testToEitherStreamEmpty() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.finish()
        }

        var results: [Either<any Error, Int>] = []
        for await value in stream.toEitherStream() {
            results.append(value)
        }

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - toThrowingStream

    func testToThrowingStreamAllRights() async throws {
        let stream = AsyncStream<Either<TestError, Int>> { continuation in
            continuation.yield(.right(1))
            continuation.yield(.right(2))
            continuation.yield(.right(3))
            continuation.finish()
        }

        var results: [Int] = []
        for try await value in stream.toThrowingStream() as AsyncThrowingStream<Int, any Error> {
            results.append(value)
        }

        XCTAssertEqual(results, [1, 2, 3])
    }

    func testToThrowingStreamLeftThrows() async {
        let stream = AsyncStream<Either<TestError, Int>> { continuation in
            continuation.yield(.right(1))
            continuation.yield(.left(.fail))
            continuation.yield(.right(2)) // never reached
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

    func testRoundTripThroughEitherStream() async throws {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(10)
            continuation.yield(20)
            continuation.finish()
        }

        var results: [Int] = []
        for try await value in stream.toEitherStream().toThrowingStream() as AsyncThrowingStream<Int, any Error> {
            results.append(value)
        }

        XCTAssertEqual(results, [10, 20])
    }

    func testRoundTripErrorThroughEitherStream() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(10)
            continuation.finish(throwing: TestError.fail)
        }

        var results: [Int] = []
        var caughtError: TestError?

        do {
            for try await value in stream.toEitherStream().toThrowingStream() as AsyncThrowingStream<Int, any Error> {
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
