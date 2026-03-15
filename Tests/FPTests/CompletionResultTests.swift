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
        let completion = result.result()

        if case .finished = completion {
            // Success
        } else {
            XCTFail("Expected .finished")
        }
    }

    func testResultFailureToCompletion() {
        let result: Result<Void, TestError> = .failure(.test)
        let completion = result.result()

        if case .failure(let error) = completion {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .failure")
        }
    }

    // MARK: - Round Trip Tests

    func testRoundTripSuccess() {
        let original: Result<Void, TestError> = .success(())
        let completion = original.result()
        let result = Result<Void, TestError>.from(completion)

        if case .success = result {
            // Success
        } else {
            XCTFail("Expected success after round trip")
        }
    }

    func testRoundTripFailure() {
        let original: Result<Void, TestError> = .failure(.test)
        let completion = original.result()
        let result = Result<Void, TestError>.from(completion)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected failure after round trip")
        }
    }
}
