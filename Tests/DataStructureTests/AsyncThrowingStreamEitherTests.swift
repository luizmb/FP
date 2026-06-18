// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct AsyncThrowingStreamEitherTests {
    struct TestError: Error, Equatable {
        let message: String
        static let fail = TestError(message: "fail")
    }

    // MARK: - toEitherStream

    @Test func toEitherStreamAllElements() async {
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

        #expect(results.count == 3)
        #expect(Either<any Error, Int>.prism.right.preview(results[0]) == 1)
        #expect(Either<any Error, Int>.prism.right.preview(results[1]) == 2)
        #expect(Either<any Error, Int>.prism.right.preview(results[2]) == 3)
    }

    @Test func toEitherStreamWithError() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(1)
            continuation.finish(throwing: TestError.fail)
        }

        var results: [Either<any Error, Int>] = []
        for await value in stream.toEitherStream() {
            results.append(value)
        }

        #expect(results.count == 2)
        #expect(Either<any Error, Int>.prism.right.preview(results[0]) == 1)
        guard case .left(let error) = results[1] else {
            Issue.record("Expected .left error")
            return
        }
        #expect(error as? TestError == .fail)
    }

    @Test func toEitherStreamEmpty() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.finish()
        }

        var results: [Either<any Error, Int>] = []
        for await value in stream.toEitherStream() {
            results.append(value)
        }

        #expect(results.isEmpty)
    }

    // MARK: - toThrowingStream

    @Test func toThrowingStreamAllRights() async throws {
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

        #expect(results == [1, 2, 3])
    }

    @Test func toThrowingStreamLeftThrows() async {
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
            Issue.record("Unexpected error: \(error)")
        }

        #expect(results == [1])
        #expect(caughtError == .fail)
    }

    // MARK: - Round trip

    @Test func roundTripThroughEitherStream() async throws {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(10)
            continuation.yield(20)
            continuation.finish()
        }

        var results: [Int] = []
        for try await value in stream.toEitherStream().toThrowingStream() as AsyncThrowingStream<Int, any Error> {
            results.append(value)
        }

        #expect(results == [10, 20])
    }

    @Test func roundTripErrorThroughEitherStream() async {
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
            Issue.record("Unexpected error: \(error)")
        }

        #expect(results == [10])
        #expect(caughtError == .fail)
    }
}
