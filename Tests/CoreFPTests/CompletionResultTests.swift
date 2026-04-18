#if canImport(Combine)
import Combine
@testable import CoreFP
import Testing
@MainActor
@Suite struct CompletionResultTests {
    enum TestError: Error, Equatable {
        case test
        case other
    }

    // MARK: - Result to Completion

    @Test func resultSuccessToCompletion() {
        let result: Result<Void, TestError> = .success(())
        let completion = result.completion()

        if case .finished = completion {
            // Success
        } else {
            Issue.record("Expected .finished")
        }
    }

    @Test func resultFailureToCompletion() {
        let result: Result<Void, TestError> = .failure(.test)
        let completion = result.completion()

        if case .failure(let error) = completion {
            #expect(error == .test)
        } else {
            Issue.record("Expected .failure")
        }
    }

    // MARK: - Completion to Result

    @Test func completionFinishedToResult() {
        let completion: Subscribers.Completion<TestError> = .finished
        let result = completion.result

        if case .success = result {
            // Success
        } else {
            Issue.record("Expected .success")
        }
    }

    @Test func completionFailureToResult() {
        let completion: Subscribers.Completion<TestError> = .failure(.test)
        let result = completion.result

        if case .failure(let error) = result {
            #expect(error == .test)
        } else {
            Issue.record("Expected .failure")
        }
    }

    // MARK: - Round Trip Tests

    @Test func roundTripResultToCompletionToResult() {
        let original: Result<Void, TestError> = .success(())
        let completion = original.completion()
        let result = completion.result

        if case .success = result {
            // Success
        } else {
            Issue.record("Expected success after round trip")
        }
    }

    @Test func roundTripResultFailureToCompletionToResult() {
        let original: Result<Void, TestError> = .failure(.test)
        let completion = original.completion()
        let result = completion.result

        if case .failure(let error) = result {
            #expect(error == .test)
        } else {
            Issue.record("Expected failure after round trip")
        }
    }

    @Test func roundTripCompletionFinishedToResultToCompletion() {
        let original: Subscribers.Completion<TestError> = .finished
        let result = original.result
        let completion = result.completion()

        if case .finished = completion {
            // Success
        } else {
            Issue.record("Expected .finished after round trip")
        }
    }

    @Test func roundTripCompletionFailureToResultToCompletion() {
        let original: Subscribers.Completion<TestError> = .failure(.test)
        let result = original.result
        let completion = result.completion()

        if case .failure(let error) = completion {
            #expect(error == .test)
        } else {
            Issue.record("Expected .failure after round trip")
        }
    }
}
#endif
