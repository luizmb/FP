// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
@testable import CoreFP
import DataStructure
import Testing

@MainActor
@Suite struct CompletionEitherTests {
    enum TestError: Error, Equatable {
        case test
        case other
    }

    // MARK: - Either to Completion

    @Test func eitherRightToCompletion() {
        let either: Either<TestError, Void> = .right(())
        let completion = either.completion()

        if case .finished = completion {
            // Success
        } else {
            Issue.record("Expected .finished")
        }
    }

    @Test func eitherLeftToCompletion() {
        let either: Either<TestError, Void> = .left(.test)
        let completion = either.completion()

        if case .failure(let error) = completion {
            #expect(error == .test)
        } else {
            Issue.record("Expected .failure")
        }
    }

    // MARK: - Completion to Either (Parallel)

    @Test func completionFinishedToEitherParallel() {
        let completion: Subscribers.Completion<TestError> = .finished
        let either = completion.either.parallel()

        // Subscribers.Completion<TestError> has A=Void, B=TestError
        // So parallel gives Either<Void, TestError>
        if case .left = either {
            // Success - .finished maps to .left(())
        } else {
            Issue.record("Expected .left")
        }
    }

    @Test func completionFailureToEitherParallel() {
        let completion: Subscribers.Completion<TestError> = .failure(.test)
        let either = completion.either.parallel()

        // parallel gives Either<Void, TestError>
        if case .right(let error) = either {
            #expect(error == .test)
        } else {
            Issue.record("Expected .right")
        }
    }

    // MARK: - Completion to Either (Crossover)

    @Test func completionFinishedToEitherCrossover() {
        let completion: Subscribers.Completion<TestError> = .finished
        let either = completion.either.crossover()

        // crossover inverts, giving Either<TestError, Void>
        if case .right = either {
            // Success - .finished maps to .right(())
        } else {
            Issue.record("Expected .right")
        }
    }

    @Test func completionFailureToEitherCrossover() {
        let completion: Subscribers.Completion<TestError> = .failure(.test)
        let either = completion.either.crossover()

        // crossover inverts, giving Either<TestError, Void>
        if case .left(let error) = either {
            #expect(error == .test)
        } else {
            Issue.record("Expected .left")
        }
    }

    // MARK: - Round Trip Tests

    @Test func roundTripFinished() {
        let original: Subscribers.Completion<TestError> = .finished
        let either = original.either.crossover()
        let completion = either.completion()

        if case .finished = completion {
            // Success
        } else {
            Issue.record("Expected .finished after round trip")
        }
    }

    @Test func roundTripFailure() {
        let original: Subscribers.Completion<TestError> = .failure(.test)
        let either = original.either.crossover()
        let completion = either.completion()

        if case .failure(let error) = completion {
            #expect(error == .test)
        } else {
            Issue.record("Expected .failure after round trip")
        }
    }

    // MARK: - SumType Tests

    @Test func completionAsSumTypeFinished() {
        let completion: Subscribers.Completion<TestError> = .finished
        let result = completion.match(
            caseLeft: const("finished"),
            caseRight: const("failed")
        )

        #expect(result == "finished")
    }

    @Test func completionAsSumTypeFailure() {
        let completion: Subscribers.Completion<TestError> = .failure(.test)
        let result = completion.match(
            caseLeft: const("finished"),
            caseRight: { error in "failed: \(error)" }
        )

        #expect(result == "failed: test")
    }

    @Test func completionConstructionViaLeft() {
        let completion = Subscribers.Completion<TestError>.left(())
        if case .finished = completion {
            // Success
        } else {
            Issue.record("Expected .finished")
        }
    }

    @Test func completionConstructionViaRight() {
        let completion = Subscribers.Completion<TestError>.right(.test)
        if case .failure(let error) = completion {
            #expect(error == .test)
        } else {
            Issue.record("Expected .failure")
        }
    }
}
#endif
