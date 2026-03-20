import XCTest
import Combine
@testable import FP
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
final class CompletionResultTests: XCTestCase {

    enum TestError: Error, Equatable {
        case test
        case other
    }

    // MARK: - Result to Completion

    func testResultSuccessToCompletion() {
        let result: Result<Void, TestError> = .success(())
        let completion = result.completion()

        if case .finished = completion {
            // Success
        } else {
            XCTFail("Expected .finished")
        }
    }

    func testResultFailureToCompletion() {
        let result: Result<Void, TestError> = .failure(.test)
        let completion = result.completion()

        if case .failure(let error) = completion {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .failure")
        }
    }

    // MARK: - Completion to Result

    func testCompletionFinishedToResult() {
        let completion: Subscribers.Completion<TestError> = .finished
        let result = completion.result

        if case .success = result {
            // Success
        } else {
            XCTFail("Expected .success")
        }
    }

    func testCompletionFailureToResult() {
        let completion: Subscribers.Completion<TestError> = .failure(.test)
        let result = completion.result

        if case .failure(let error) = result {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .failure")
        }
    }

    // MARK: - Round Trip Tests

    func testRoundTripResultToCompletionToResult() {
        let original: Result<Void, TestError> = .success(())
        let completion = original.completion()
        let result = completion.result

        if case .success = result {
            // Success
        } else {
            XCTFail("Expected success after round trip")
        }
    }

    func testRoundTripResultFailureToCompletionToResult() {
        let original: Result<Void, TestError> = .failure(.test)
        let completion = original.completion()
        let result = completion.result

        if case .failure(let error) = result {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected failure after round trip")
        }
    }

    func testRoundTripCompletionFinishedToResultToCompletion() {
        let original: Subscribers.Completion<TestError> = .finished
        let result = original.result
        let completion = result.completion()

        if case .finished = completion {
            // Success
        } else {
            XCTFail("Expected .finished after round trip")
        }
    }

    func testRoundTripCompletionFailureToResultToCompletion() {
        let original: Subscribers.Completion<TestError> = .failure(.test)
        let result = original.result
        let completion = result.completion()

        if case .failure(let error) = completion {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .failure after round trip")
        }
    }
}
