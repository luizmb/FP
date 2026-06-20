// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct BitraversableTests {
    private enum TestError: Error, Equatable { case fail }

    // MARK: - Either + Array

    @Test func eitherBitraverseArrayLeft() {
        let e: Either<String, Int> = .left("ab")
        // lf maps length -> repeated; rf is irrelevant
        let result = e.bitraverse({ Array(repeating: $0, count: $0.count) }, { [$0] })
        #expect(result == [.left("ab"), .left("ab")])
    }

    @Test func eitherBitraverseArrayRight() {
        let e: Either<String, Int> = .right(3)
        let result = e.bitraverse({ [$0] }, { [$0, $0 * 2] })
        #expect(result == [.right(3), .right(6)])
    }

    @Test func eitherBisequenceArray() {
        let left: Either<[String], [Int]> = .left(["a", "b"])
        #expect(left.bisequence() == [.left("a"), .left("b")])

        let right: Either<[String], [Int]> = .right([1, 2])
        #expect(right.bisequence() == [.right(1), .right(2)])
    }

    @Test func eitherBitraverseArrayFreeFunction() {
        let f: (Either<String, Int>) -> [Either<String, Int>] = bitraverse({ [$0, $0] }, { [$0] })
        let result = f(.left("x"))
        #expect(result == [.left("x"), .left("x")])
    }

    // MARK: - Either + Optional

    @Test func eitherBitraverseOptionalLeftPresent() {
        let e: Either<String, Int> = .left("hi")
        let result = e.bitraverse({ Optional($0.uppercased()) }, const(nil as Int?))
        #expect(result == .some(.left("HI")))
    }

    @Test func eitherBitraverseOptionalLeftAbsent() {
        let e: Either<String, Int> = .left("hi")
        let result = e.bitraverse(const(nil as String?)) { Optional($0) }
        #expect(result == .none)
    }

    @Test func eitherBitraverseOptionalRightPresent() {
        let e: Either<String, Int> = .right(5)
        let result = e.bitraverse(const(nil as String?)) { Optional($0 * 2) }
        #expect(result == .some(.right(10)))
    }

    @Test func eitherBitraverseOptionalRightAbsent() {
        let e: Either<String, Int> = .right(5)
        let result = e.bitraverse({ Optional($0) }, const(nil as Int?))
        #expect(result == .none)
    }

    @Test func eitherBisequenceOptional() {
        let left: Either<String?, Int?> = .left(.some("ok"))
        #expect(left.bisequence() == .some(.left("ok")))

        let leftNone: Either<String?, Int?> = .left(.none)
        #expect(leftNone.bisequence() == .none)

        let right: Either<String?, Int?> = .right(.some(7))
        #expect(right.bisequence() == .some(.right(7)))

        let rightNone: Either<String?, Int?> = .right(.none)
        #expect(rightNone.bisequence() == .none)
    }

    // MARK: - Either + Result

    @Test func eitherBitraverseResultLeftSuccess() {
        let e: Either<String, Int> = .left("hi")
        let result = e.bitraverse(
            { Result<String, TestError>.success($0.uppercased()) },
            const(Result<Int, TestError>.failure(.fail))
        )
        #expect(result == .success(.left("HI")))
    }

    @Test func eitherBitraverseResultLeftFailure() {
        let e: Either<String, Int> = .left("hi")
        let result = e.bitraverse(
            const(Result<String, TestError>.failure(.fail)),
            { Result<Int, TestError>.success($0) }
        )
        #expect(result == .failure(.fail))
    }

    @Test func eitherBitraverseResultRightSuccess() {
        let e: Either<String, Int> = .right(3)
        let result = e.bitraverse(
            const(Result<String, TestError>.failure(.fail)),
            { Result<Int, TestError>.success($0 * 2) }
        )
        #expect(result == .success(.right(6)))
    }

    @Test func eitherBitraverseResultRightFailure() {
        let e: Either<String, Int> = .right(3)
        let result = e.bitraverse(
            { Result<String, TestError>.success($0) },
            const(Result<Int, TestError>.failure(.fail))
        )
        #expect(result == .failure(.fail))
    }

    @Test func eitherBisequenceResult() {
        let left: Either<Result<String, TestError>, Result<Int, TestError>> = .left(.success("ok"))
        #expect(left.bisequence() == .success(.left("ok")))

        let leftFail: Either<Result<String, TestError>, Result<Int, TestError>> = .left(.failure(.fail))
        #expect(leftFail.bisequence() == .failure(.fail))

        let right: Either<Result<String, TestError>, Result<Int, TestError>> = .right(.success(9))
        #expect(right.bisequence() == .success(.right(9)))
    }

    // MARK: - Validation + Array

    @Test func validationBitraverseArrayFailure() {
        let v: Validation<String, Int> = .failure("err")
        let result = v.bitraverse({ [$0, $0.uppercased()] }, { [$0] })
        #expect(result == [.failure("err"), .failure("ERR")])
    }

    @Test func validationBitraverseArraySuccess() {
        let v: Validation<String, Int> = .success(3)
        let result = v.bitraverse({ [$0] }, { [$0, $0 * 2] })
        #expect(result == [.success(3), .success(6)])
    }

    @Test func validationBisequenceArray() {
        let failure: Validation<[String], [Int]> = .failure(["a", "b"])
        #expect(failure.bisequence() == [.failure("a"), .failure("b")])

        let success: Validation<[String], [Int]> = .success([1, 2])
        #expect(success.bisequence() == [.success(1), .success(2)])
    }

    // MARK: - Validation + Optional

    @Test func validationBitraverseOptionalFailurePresent() {
        let v: Validation<String, Int> = .failure("err")
        let result = v.bitraverse({ Optional($0.uppercased()) }, const(nil as Int?))
        #expect(result == .some(.failure("ERR")))
    }

    @Test func validationBitraverseOptionalFailureAbsent() {
        let v: Validation<String, Int> = .failure("err")
        let result = v.bitraverse(const(nil as String?)) { Optional($0) }
        #expect(result == .none)
    }

    @Test func validationBitraverseOptionalSuccessPresent() {
        let v: Validation<String, Int> = .success(5)
        let result = v.bitraverse(const(nil as String?)) { Optional($0 * 2) }
        #expect(result == .some(.success(10)))
    }

    @Test func validationBitraverseOptionalSuccessAbsent() {
        let v: Validation<String, Int> = .success(5)
        let result = v.bitraverse({ Optional($0) }, const(nil as Int?))
        #expect(result == .none)
    }

    @Test func validationBisequenceOptional() {
        let failureSome: Validation<String?, Int?> = .failure(.some("e"))
        #expect(failureSome.bisequence() == .some(.failure("e")))

        let failureNone: Validation<String?, Int?> = .failure(.none)
        #expect(failureNone.bisequence() == .none)

        let successSome: Validation<String?, Int?> = .success(.some(3))
        #expect(successSome.bisequence() == .some(.success(3)))

        let successNone: Validation<String?, Int?> = .success(.none)
        #expect(successNone.bisequence() == .none)
    }

    // MARK: - Validation + Result

    @Test func validationBitraverseResultFailureSuccess() {
        let v: Validation<String, Int> = .failure("err")
        let result = v.bitraverse(
            { Result<String, TestError>.success($0.uppercased()) },
            const(Result<Int, TestError>.failure(.fail))
        )
        #expect(result == .success(.failure("ERR")))
    }

    @Test func validationBitraverseResultFailureFailure() {
        let v: Validation<String, Int> = .failure("err")
        let result = v.bitraverse(
            const(Result<String, TestError>.failure(.fail)),
            { Result<Int, TestError>.success($0) }
        )
        #expect(result == .failure(.fail))
    }

    @Test func validationBitraverseResultSuccessSuccess() {
        let v: Validation<String, Int> = .success(3)
        let result = v.bitraverse(
            const(Result<String, TestError>.failure(.fail)),
            { Result<Int, TestError>.success($0 * 2) }
        )
        #expect(result == .success(.success(6)))
    }

    @Test func validationBitraverseResultSuccessFailure() {
        let v: Validation<String, Int> = .success(3)
        let result = v.bitraverse(
            { Result<String, TestError>.success($0) },
            const(Result<Int, TestError>.failure(.fail))
        )
        #expect(result == .failure(.fail))
    }

    // Note: bisequence for Validation + Result effect is not available since Result<E1, Err>
    // does not conform to Semigroup unconditionally, making Validation<Result<…>, …> an invalid type.
}
