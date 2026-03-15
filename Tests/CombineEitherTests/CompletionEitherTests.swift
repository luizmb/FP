import XCTest
import Combine
@testable import FP
@testable import Either
@testable import CombineEither
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
final class CompletionEitherTests: XCTestCase {

    enum TestError: Error, Equatable {
        case test
        case other
    }

    // MARK: - Either to Completion

    func testEitherRightToCompletion() {
        let either: Either<TestError, Void> = .right(())
        let completion = either.completion()

        if case .finished = completion {
            // Success
        } else {
            XCTFail("Expected .finished")
        }
    }

    func testEitherLeftToCompletion() {
        let either: Either<TestError, Void> = .left(.test)
        let completion = either.completion()

        if case .failure(let error) = completion {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .failure")
        }
    }

    // MARK: - Completion to Either (Parallel)

    func testCompletionFinishedToEitherParallel() {
        let completion: Subscribers.Completion<TestError> = .finished
        let either = completion.either.parallel()

        // Subscribers.Completion<TestError> has A=Void, B=TestError
        // So parallel gives Either<Void, TestError>
        if case .left = either {
            // Success - .finished maps to .left(())
        } else {
            XCTFail("Expected .left")
        }
    }

    func testCompletionFailureToEitherParallel() {
        let completion: Subscribers.Completion<TestError> = .failure(.test)
        let either = completion.either.parallel()

        // parallel gives Either<Void, TestError>
        if case .right(let error) = either {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .right")
        }
    }

    // MARK: - Completion to Either (Crossover)

    func testCompletionFinishedToEitherCrossover() {
        let completion: Subscribers.Completion<TestError> = .finished
        let either = completion.either.crossover()

        // crossover inverts, giving Either<TestError, Void>
        if case .right = either {
            // Success - .finished maps to .right(())
        } else {
            XCTFail("Expected .right")
        }
    }

    func testCompletionFailureToEitherCrossover() {
        let completion: Subscribers.Completion<TestError> = .failure(.test)
        let either = completion.either.crossover()

        // crossover inverts, giving Either<TestError, Void>
        if case .left(let error) = either {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .left")
        }
    }

    // MARK: - Round Trip Tests

    func testRoundTripFinished() {
        let original: Subscribers.Completion<TestError> = .finished
        let either = original.either.crossover()
        let completion = either.completion()

        if case .finished = completion {
            // Success
        } else {
            XCTFail("Expected .finished after round trip")
        }
    }

    func testRoundTripFailure() {
        let original: Subscribers.Completion<TestError> = .failure(.test)
        let either = original.either.crossover()
        let completion = either.completion()

        if case .failure(let error) = completion {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .failure after round trip")
        }
    }

    // MARK: - SumType Tests

    func testCompletionAsSumTypeFinished() {
        let completion: Subscribers.Completion<TestError> = .finished
        let result = completion.match(
            caseLeft: { _ in "finished" },
            caseRight: { _ in "failed" }
        )

        XCTAssertEqual(result, "finished")
    }

    func testCompletionAsSumTypeFailure() {
        let completion: Subscribers.Completion<TestError> = .failure(.test)
        let result = completion.match(
            caseLeft: { _ in "finished" },
            caseRight: { error in "failed: \(error)" }
        )

        XCTAssertEqual(result, "failed: test")
    }

    func testCompletionConstructionViaLeft() {
        let completion = Subscribers.Completion<TestError>.left(())
        if case .finished = completion {
            // Success
        } else {
            XCTFail("Expected .finished")
        }
    }

    func testCompletionConstructionViaRight() {
        let completion = Subscribers.Completion<TestError>.right(.test)
        if case .failure(let error) = completion {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected .failure")
        }
    }
}
