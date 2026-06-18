// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct DataStructureTraversableTests {
    private enum TestError: Error, Equatable { case fail }

    // MARK: - Either as Traversable (in right/B)

    // traverse :: (b -> [c]) -> Either a b -> [Either a c]

    @Test func eitherTraverseArrayLeft() {
        // Left is untouched — wrapped in singleton list
        let e: Either<String, Int> = .left("error")
        #expect(e.traverse { [$0, $0 * 2] } == [.left("error")])
    }

    @Test func eitherTraverseArrayRight() {
        // Right maps through f, results wrapped in Right
        let e: Either<String, Int> = .right(3)
        #expect(e.traverse { [$0, $0 * 2] } == [.right(3), .right(6)])
    }

    @Test func eitherSequenceArray() {
        let left: Either<String, [Int]> = .left("err")
        #expect(left.sequence() == [.left("err")])

        let right: Either<String, [Int]> = .right([1, 2])
        #expect(right.sequence() == [.right(1), .right(2)])
    }

    // traverse :: (b -> c?) -> Either a b -> Either a c?

    @Test func eitherTraverseOptionalLeft() {
        let e: Either<String, Int> = .left("error")
        let result = e.traverse { Optional($0 * 2) }
        #expect(result == .some(.left("error")))
    }

    @Test func eitherTraverseOptionalRightSuccess() {
        let e: Either<String, Int> = .right(3)
        let result = e.traverse { Optional($0 * 2) }
        #expect(result == .some(.right(6)))
    }

    @Test func eitherTraverseOptionalRightFailure() {
        let e: Either<String, Int> = .right(3)
        let result = e.traverse(const(nil as Int?))
        #expect(result == .none)
    }

    @Test func eitherSequenceOptional() {
        let left: Either<String, Int?> = .left("err")
        #expect(left.sequence() == .some(.left("err")))

        let rightSome: Either<String, Int?> = .right(.some(5))
        #expect(rightSome.sequence() == .some(.right(5)))

        let rightNone: Either<String, Int?> = .right(.none)
        #expect(rightNone.sequence() == .none)
    }

    // traverse :: (b -> Result<c, e>) -> Either a b -> Result<Either a c, e>

    @Test func eitherTraverseResultLeft() {
        let e: Either<String, Int> = .left("error")
        let result = e.traverse { Result<Int, TestError>.success($0 * 2) }
        #expect(result == .success(.left("error")))
    }

    @Test func eitherTraverseResultRightSuccess() {
        let e: Either<String, Int> = .right(3)
        let result = e.traverse { Result<Int, TestError>.success($0 * 2) }
        #expect(result == .success(.right(6)))
    }

    @Test func eitherTraverseResultRightFailure() {
        let e: Either<String, Int> = .right(3)
        let result = e.traverse(const(Result<Int, TestError>.failure(.fail)))
        #expect(result == .failure(.fail))
    }

    @Test func eitherSequenceResult() {
        let left: Either<String, Result<Int, TestError>> = .left("err")
        #expect(left.sequence() == .success(.left("err")))

        let rightSuccess: Either<String, Result<Int, TestError>> = .right(.success(7))
        #expect(rightSuccess.sequence() == .success(.right(7)))

        let rightFailure: Either<String, Result<Int, TestError>> = .right(.failure(.fail))
        #expect(rightFailure.sequence() == .failure(.fail))
    }

    // MARK: - Validation as Traversable (in success/A)

    // traverse :: (a -> [b]) -> Validation e a -> [Validation e b]

    @Test func validationTraverseArrayFailure() {
        let v: Validation<String, Int> = .failure("err")
        #expect(v.traverse { [$0, $0 * 2] } == [.failure("err")])
    }

    @Test func validationTraverseArraySuccess() {
        let v: Validation<String, Int> = .success(3)
        #expect(v.traverse { [$0, $0 * 2] } == [.success(3), .success(6)])
    }

    @Test func validationSequenceArray() {
        let failure: Validation<String, [Int]> = .failure("err")
        #expect(failure.sequence() == [.failure("err")])

        let success: Validation<String, [Int]> = .success([1, 2])
        #expect(success.sequence() == [.success(1), .success(2)])
    }

    // traverse :: (a -> b?) -> Validation e a -> Validation e b?

    @Test func validationTraverseOptionalFailure() {
        let v: Validation<String, Int> = .failure("err")
        let result = v.traverse { Optional($0 * 2) }
        #expect(result == .some(.failure("err")))
    }

    @Test func validationTraverseOptionalSuccessPresent() {
        let v: Validation<String, Int> = .success(3)
        let result = v.traverse { Optional($0 * 2) }
        #expect(result == .some(.success(6)))
    }

    @Test func validationTraverseOptionalSuccessAbsent() {
        let v: Validation<String, Int> = .success(3)
        let result = v.traverse(const(nil as Int?))
        #expect(result == .none)
    }

    @Test func validationSequenceOptional() {
        let failure: Validation<String, Int?> = .failure("err")
        #expect(failure.sequence() == .some(.failure("err")))

        let successSome: Validation<String, Int?> = .success(.some(5))
        #expect(successSome.sequence() == .some(.success(5)))

        let successNone: Validation<String, Int?> = .success(.none)
        #expect(successNone.sequence() == .none)
    }

    // traverse :: (a -> Result<b, e2>) -> Validation e a -> Result<Validation e b, e2>

    @Test func validationTraverseResultFailure() {
        let v: Validation<String, Int> = .failure("err")
        let result = v.traverse { Result<Int, TestError>.success($0 * 2) }
        #expect(result == .success(.failure("err")))
    }

    @Test func validationTraverseResultSuccessOk() {
        let v: Validation<String, Int> = .success(3)
        let result = v.traverse { Result<Int, TestError>.success($0 * 2) }
        #expect(result == .success(.success(6)))
    }

    @Test func validationTraverseResultSuccessErr() {
        let v: Validation<String, Int> = .success(3)
        let result = v.traverse(const(Result<Int, TestError>.failure(.fail)))
        #expect(result == .failure(.fail))
    }

    @Test func validationSequenceResult() {
        let failure: Validation<String, Result<Int, TestError>> = .failure("err")
        #expect(failure.sequence() == .success(.failure("err")))

        let successOk: Validation<String, Result<Int, TestError>> = .success(.success(7))
        #expect(successOk.sequence() == .success(.success(7)))

        let successErr: Validation<String, Result<Int, TestError>> = .success(.failure(.fail))
        #expect(successErr.sequence() == .failure(.fail))
    }

    // MARK: - Writer as Traversable (in value/A)

    // traverse :: (a -> [b]) -> Writer w a -> [Writer w b]

    @Test func writerTraverseArray() {
        let w = Writer<String, Int>(3, "log")
        let result = w.traverse { [$0, $0 * 2] }
        #expect(result.count == 2)
        #expect(result[0].value == 3 && result[0].log == "log")
        #expect(result[1].value == 6 && result[1].log == "log")
    }

    @Test func writerSequenceArray() {
        let w = Writer<String, [Int]>([1, 2], "log")
        let result = w.sequence()
        #expect(result.count == 2)
        #expect(result[0].value == 1 && result[0].log == "log")
        #expect(result[1].value == 2 && result[1].log == "log")
    }

    @Test func writerTraverseArrayPreservesLog() {
        let w = Writer<String, Int>(5, "mylog")
        let result = w.traverse { [$0 + 1] }
        #expect(result.count == 1)
        #expect(result[0].value == 6)
        #expect(result[0].log == "mylog")
    }

    // traverse :: (a -> b?) -> Writer w a -> Writer w b?

    @Test func writerTraverseOptionalPresent() {
        let w = Writer<String, Int>(3, "log")
        let result = w.traverse { Optional($0 * 2) }
        #expect(result?.value == 6)
        #expect(result?.log == "log")
    }

    @Test func writerTraverseOptionalAbsent() {
        let w = Writer<String, Int>(3, "log")
        let result = w.traverse(const(nil as Int?))
        #expect(result == nil)
    }

    @Test func writerSequenceOptional() {
        let wSome = Writer<String, Int?>(.some(4), "log")
        let resultSome = wSome.sequence()
        #expect(resultSome?.value == 4)
        #expect(resultSome?.log == "log")

        let wNone = Writer<String, Int?>(.none, "log")
        #expect(wNone.sequence() == nil)
    }

    // traverse :: (a -> Result<b, e>) -> Writer w a -> Result<Writer w b, e>

    @Test func writerTraverseResultSuccess() {
        let w = Writer<String, Int>(3, "log")
        let result = w.traverse { Result<Int, TestError>.success($0 * 2) }
        #expect(result == .success(Writer<String, Int>(6, "log")))
    }

    @Test func writerTraverseResultFailure() {
        let w = Writer<String, Int>(3, "log")
        let result = w.traverse(const(Result<Int, TestError>.failure(.fail)))
        #expect(result == .failure(.fail))
    }

    @Test func writerSequenceResult() {
        let wSuccess = Writer<String, Result<Int, TestError>>(.success(5), "log")
        #expect(wSuccess.sequence() == .success(Writer<String, Int>(5, "log")))

        let wFailure = Writer<String, Result<Int, TestError>>(.failure(.fail), "log")
        #expect(wFailure.sequence() == .failure(.fail))
    }
}
