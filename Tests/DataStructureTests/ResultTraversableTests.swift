// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ResultTraversableTests {
    private enum TestError: Error, Equatable { case fail }

    // MARK: - traverse :: (a -> Either<l, c>) -> Result a e -> Either<l, Result c e>

    @Test func traverseEitherFailure() {
        let r: Result<Int, TestError> = .failure(.fail)
        let result = r.traverse { Either<String, Int>.right($0 * 2) }
        #expect(result == .right(.failure(.fail)))
    }

    @Test func traverseEitherSuccessRight() {
        let r: Result<Int, TestError> = .success(3)
        let result = r.traverse { Either<String, Int>.right($0 * 2) }
        #expect(result == .right(.success(6)))
    }

    @Test func traverseEitherSuccessLeft() {
        let r: Result<Int, TestError> = .success(3)
        let result = r.traverse(const(Either<String, Int>.left("boom")))
        #expect(result == .left("boom"))
    }

    @Test func sequenceEither() {
        let failure: Result<Either<String, Int>, TestError> = .failure(.fail)
        #expect(sequence(failure) == .right(.failure(.fail)))

        let successRight: Result<Either<String, Int>, TestError> = .success(.right(5))
        #expect(sequence(successRight) == .right(.success(5)))

        let successLeft: Result<Either<String, Int>, TestError> = .success(.left("boom"))
        #expect(sequence(successLeft) == .left("boom"))
    }

    // MARK: - traverse :: (a -> Validation<e2, c>) -> Result a e -> Validation<e2, Result c e>

    @Test func traverseValidationFailure() {
        let r: Result<Int, TestError> = .failure(.fail)
        let result = r.traverse { Validation<[String], Int>.success($0 * 2) }
        #expect(result == .success(.failure(.fail)))
    }

    @Test func traverseValidationSuccessSuccess() {
        let r: Result<Int, TestError> = .success(3)
        let result = r.traverse { Validation<[String], Int>.success($0 * 2) }
        #expect(result == .success(.success(6)))
    }

    @Test func traverseValidationSuccessFailure() {
        let r: Result<Int, TestError> = .success(3)
        let result = r.traverse(const(Validation<[String], Int>.failure(["boom"])))
        #expect(result == .failure(["boom"]))
    }

    @Test func sequenceValidation() {
        let failure: Result<Validation<[String], Int>, TestError> = .failure(.fail)
        #expect(sequence(failure) == .success(.failure(.fail)))

        let successSuccess: Result<Validation<[String], Int>, TestError> = .success(.success(5))
        #expect(sequence(successSuccess) == .success(.success(5)))

        let successFailure: Result<Validation<[String], Int>, TestError> = .success(.failure(["boom"]))
        #expect(sequence(successFailure) == .failure(["boom"]))
    }
}
