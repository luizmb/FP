import XCTest
@testable import Either
import FP
@testable import EitherOperators
import Operators

final class EitherMonadTests: XCTestCase {

    // MARK: - Basic Monad Tests

    func testFlatMap() {
        let value: Either<String, Int> = .right(5)
        let result = value.flatMap { x in .right(x * 2) }
        XCTAssertEqual(result, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.flatMap { x in .right(x * 2) }
        XCTAssertEqual(leftResult, .left("error"))

        let errorResult: Either<String, Int> = .right(5)
        let errorFlatMap = errorResult.flatMap { _ in Either<String, Int>.left("new error") }
        XCTAssertEqual(errorFlatMap, .left("new error"))
    }

    func testBind() {
        let transform: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let value: Either<String, Int> = .right(5)
        let result = Either.bind(transform)(value)
        XCTAssertEqual(result, .right(10))
    }

    func testJoin() {
        // join is flatMap with identity
        let nested: Either<String, Either<String, Int>> = .right(.right(5))
        let result = nested.flatMap { $0 }
        XCTAssertEqual(result, .right(5))

        let nestedLeft: Either<String, Either<String, Int>> = .right(.left("inner error"))
        let nestedLeftResult = nestedLeft.flatMap { $0 }
        XCTAssertEqual(nestedLeftResult, .left("inner error"))

        let outerLeft: Either<String, Either<String, Int>> = .left("outer error")
        let outerLeftResult = outerLeft.flatMap { $0 }
        XCTAssertEqual(outerLeftResult, .left("outer error"))
    }

    // MARK: - Monad Laws

    func testMonadLeftIdentityLaw() {
        // return a >>= f == f a
        let a = 5
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }

        let left = Either<String, Int>.right(a).flatMap(f)
        let right = f(a)

        XCTAssertEqual(left, right)
    }

    func testMonadRightIdentityLaw() {
        // m >>= return == m
        let m: Either<String, Int> = .right(5)
        let result = m.flatMap { Either<String, Int>.right($0) }

        XCTAssertEqual(result, m)

        let leftValue: Either<String, Int> = .left("error")
        let leftResult = leftValue.flatMap { Either<String, Int>.right($0) }
        XCTAssertEqual(leftResult, leftValue)
    }

    func testMonadAssociativityLaw() {
        // (m >>= f) >>= g == m >>= (\x -> f x >>= g)
        let m: Either<String, Int> = .right(5)
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, Int> = { .right($0 + 10) }

        let left = m.flatMap(f).flatMap(g)
        let right = m.flatMap { x in f(x).flatMap(g) }

        XCTAssertEqual(left, right)
    }

    // MARK: - Kleisli Composition

    func testKleisliComposition() {
        let f: (Int) -> Either<String, Int> = { x in
            x > 0 ? .right(x * 2) : .left("negative")
        }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = Either<String, Int>.kleisli(f, g)
        XCTAssertEqual(composed(5), .right("10"))
        XCTAssertEqual(composed(-1), .left("negative"))
    }

    func testKleisliBack() {
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = Either<String, Int>.kleisliBack(g, f)
        XCTAssertEqual(composed(5), .right("10"))
    }

    // MARK: - Monad Operators

    func testBindOperator() {
        let value: Either<String, Int> = .right(5)
        let result = value >>- { .right($0 * 2) }
        XCTAssertEqual(result, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left >>- { .right($0 * 2) }
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testFlippedBindOperator() {
        let transform: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let value: Either<String, Int> = .right(5)
        let result = transform -<< value
        XCTAssertEqual(result, .right(10))
    }

    func testKleisliOperator() {
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = f >=> g
        XCTAssertEqual(composed(5), .right("10"))
    }

    func testKleisliBackFunction() {
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = Either<String, Int>.kleisliBack(g, f)
        XCTAssertEqual(composed(5), .right("10"))
    }

    // MARK: - Alternative

    func testAlternative() {
        let right1: Either<String, Int> = .right(5)
        let right2: Either<String, Int> = .right(10)
        XCTAssertEqual(right1 <|> right2, .right(5))

        let left: Either<String, Int> = .left("error")
        XCTAssertEqual(left <|> right2, .right(10))

        let left2: Either<String, Int> = .left("error2")
        XCTAssertEqual(left <|> left2, .left("error2"))
    }
}
