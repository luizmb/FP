// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct AsyncThrowingStreamResultTests {
    struct TestError: Error, Equatable {
        let message: String
        static let fail = TestError(message: "fail")
    }

    // MARK: - toResultStream

    @Test func toResultStreamAllElements() async {
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

        #expect(results.count == 3)
        #expect((try? results[0].get()) == 1)
        #expect((try? results[1].get()) == 2)
        #expect((try? results[2].get()) == 3)
    }

    @Test func toResultStreamWithError() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(1)
            continuation.finish(throwing: TestError.fail)
        }

        var results: [Result<Int, any Error>] = []
        for await value in stream.toResultStream() {
            results.append(value)
        }

        #expect(results.count == 2)
        #expect((try? results[0].get()) == 1)
        switch results[1] {
        case .failure(let error):
            #expect(error as? TestError == .fail)

        case .success:
            Issue.record("Expected .failure")
        }
    }

    @Test func toResultStreamEmpty() async {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.finish()
        }

        var results: [Result<Int, any Error>] = []
        for await value in stream.toResultStream() {
            results.append(value)
        }

        #expect(results.isEmpty)
    }

    // MARK: - toThrowingStream

    @Test func toThrowingStreamAllSuccesses() async throws {
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

        #expect(results == [1, 2, 3])
    }

    @Test func toThrowingStreamFailureThrows() async {
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
            Issue.record("Unexpected error: \(error)")
        }

        #expect(results == [1])
        #expect(caughtError == .fail)
    }

    // MARK: - Round trip

    @Test func roundTripThroughResultStream() async throws {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(10)
            continuation.yield(20)
            continuation.finish()
        }

        var results: [Int] = []
        for try await value in stream.toResultStream().toThrowingStream() as AsyncThrowingStream<Int, any Error> {
            results.append(value)
        }

        #expect(results == [10, 20])
    }

    @Test func roundTripErrorThroughResultStream() async {
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
            Issue.record("Unexpected error: \(error)")
        }

        #expect(results == [10])
        #expect(caughtError == .fail)
    }
}
