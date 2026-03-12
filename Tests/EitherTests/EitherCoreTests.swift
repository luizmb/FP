import XCTest
@testable import Either
import FP

final class EitherCoreTests: XCTestCase {

    // MARK: - Construction

    func testLeftConstruction() {
        let either: Either<String, Int> = .left("error")

        either.match(
            caseLeft: { error in XCTAssertEqual(error, "error") },
            caseRight: { _ in XCTFail("Expected left") }
        )
    }

    func testRightConstruction() {
        let either: Either<String, Int> = .right(42)

        either.match(
            caseLeft: { _ in XCTFail("Expected right") },
            caseRight: { value in XCTAssertEqual(value, 42) }
        )
    }

    // MARK: - Pattern Matching

    func testMatchLeft() {
        let either: Either<String, Int> = .left("error")
        let result = either.match(
            caseLeft: { "left: \($0)" },
            caseRight: { "right: \($0)" }
        )

        XCTAssertEqual(result, "left: error")
    }

    func testMatchRight() {
        let either: Either<String, Int> = .right(42)
        let result = either.match(
            caseLeft: { "left: \($0)" },
            caseRight: { "right: \($0)" }
        )

        XCTAssertEqual(result, "right: 42")
    }

    // MARK: - Functor (Core Methods)

    func testFmap() {
        let right: Either<String, Int> = .right(5)
        let result = Either<String, Int>.fmap({ $0 * 2 })(right)
        XCTAssertEqual(result, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = Either<String, Int>.fmap({ $0 * 2 })(left)
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testMapRight() {
        let right: Either<String, Int> = .right(5)
        let result = right.mapRight { $0 * 2 }
        XCTAssertEqual(result, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.mapRight { $0 * 2 }
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testMapLeft() {
        let left: Either<String, Int> = .left("error")
        let result = left.mapLeft { $0.uppercased() }
        XCTAssertEqual(result, .left("ERROR"))

        let right: Either<String, Int> = .right(5)
        let rightResult = right.mapLeft { $0.uppercased() }
        XCTAssertEqual(rightResult, .right(5))
    }

    func testBimap() {
        let left: Either<String, Int> = .left("error")
        let leftResult = left.bimap({ $0.uppercased() }, { $0 * 2 })
        XCTAssertEqual(leftResult, .left("ERROR"))

        let right: Either<String, Int> = .right(5)
        let rightResult = right.bimap({ $0.uppercased() }, { $0 * 2 })
        XCTAssertEqual(rightResult, .right(10))
    }

    // MARK: - Applicative (Core Methods)

    func testLiftA2() {
        let add: (Int, Int) -> Int = { $0 + $1 }
        let liftedAdd = Either<String, Int>.liftA2(add)

        let right1: Either<String, Int> = .right(5)
        let right2: Either<String, Int> = .right(10)
        let result = liftedAdd(right1, right2)
        XCTAssertEqual(result, .right(15))

        let left: Either<String, Int> = .left("error")
        let leftResult = liftedAdd(left, right2)
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testZip() {
        let right1: Either<String, Int> = .right(5)
        let right2: Either<String, String> = .right("hello")
        let result: Either<String, (Int, String)> = Either.zip(right1, right2)

        if case .right(let tuple) = result {
            XCTAssertEqual(tuple.0, 5)
            XCTAssertEqual(tuple.1, "hello")
        } else {
            XCTFail("Expected right")
        }

        let left: Either<String, Int> = .left("error")
        let leftResult: Either<String, (Int, String)> = Either.zip(left, right2)
        if case .left(let error) = leftResult {
            XCTAssertEqual(error, "error")
        } else {
            XCTFail("Expected left")
        }
    }

    // MARK: - Monad (Core Methods)

    func testFlatMap() {
        let right: Either<String, Int> = .right(5)
        let result = right.flatMap { value in
            .right(value * 2)
        }
        XCTAssertEqual(result, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.flatMap { value in
            Either<String, Int>.right(value * 2)
        }
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testFlatMapLeftToRight() {
        let right: Either<String, Int> = .right(5)
        let result = right.flatMap { _ in
            Either<String, Int>.left("new error")
        }
        XCTAssertEqual(result, .left("new error"))
    }

    func testJoin() {
        let nested: Either<String, Either<String, Int>> = .right(.right(42))
        let result = nested.flatMap { $0 }
        XCTAssertEqual(result, .right(42))

        let nestedLeft: Either<String, Either<String, Int>> = .right(.left("inner error"))
        let leftResult = nestedLeft.flatMap { $0 }
        XCTAssertEqual(leftResult, .left("inner error"))
    }

    func testKleisli() {
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = Either<String, Int>.kleisli(f, g)
        let result = composed(5)
        XCTAssertEqual(result, .right("10"))
    }

    // MARK: - Inverted

    func testInverted() {
        let left: Either<String, Int> = .left("error")
        let inverted = left.inverted()
        XCTAssertEqual(inverted, .right("error"))

        let right: Either<String, Int> = .right(42)
        let invertedRight = right.inverted()
        XCTAssertEqual(invertedRight, .left(42))
    }

    // MARK: - Result Bridge

    func testFromResultSuccess() {
        let result: Result<Int, TestError> = .success(42)
        let either = result.either.parallel()
        XCTAssertEqual(either, Either<Int, TestError>.left(42))
    }

    func testFromResultFailure() {
        let result: Result<Int, TestError> = .failure(.test)
        let either = result.either.parallel()
        XCTAssertEqual(either, Either<Int, TestError>.right(.test))
    }

    func testToResultRight() {
        let either: Either<TestError, Int> = .right(42)
        let result = either.result()

        if case .success(let value) = result {
            XCTAssertEqual(value, 42)
        } else {
            XCTFail("Expected success")
        }
    }

    func testToResultLeft() {
        let either: Either<TestError, Int> = .left(.test)
        let result = either.result()

        if case .failure(let error) = result {
            XCTAssertEqual(error, .test)
        } else {
            XCTFail("Expected failure")
        }
    }

    // MARK: - Helper

    enum TestError: Error, Equatable {
        case test
    }
}
