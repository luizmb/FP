import XCTest
@testable import Either
import FP
@testable import EitherOperators
import Operators

final class EitherApplicativeTests: XCTestCase {

    // MARK: - Basic Applicative Tests

    func testApply() {
        let fn: Either<String, (Int) -> Int> = .right({ $0 * 2 })
        let value: Either<String, Int> = .right(5)
        let result = fn <*> value
        XCTAssertEqual(result, .right(10))

        let leftFn: Either<String, (Int) -> Int> = .left("error")
        let leftResult = leftFn <*> value
        XCTAssertEqual(leftResult, .left("error"))

        let leftValue: Either<String, Int> = .left("value error")
        let leftValueResult = fn <*> leftValue
        XCTAssertEqual(leftValueResult, .left("value error"))
    }

    func testLiftA2() {
        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted = Either<String, Int>.liftA2(add)

        let value1: Either<String, Int> = .right(5)
        let value2: Either<String, Int> = .right(3)
        let result = lifted(value1, value2)
        XCTAssertEqual(result, .right(8))

        let left1: Either<String, Int> = .left("error1")
        let leftResult = lifted(left1, value2)
        XCTAssertEqual(leftResult, .left("error1"))

        let left2: Either<String, Int> = .left("error2")
        let leftResult2 = lifted(value1, left2)
        XCTAssertEqual(leftResult2, .left("error2"))
    }

    func testZip() {
        let value1: Either<String, Int> = .right(5)
        let value2: Either<String, String> = .right("test")
        let result = Either<String, (Int, String)>.zip(value1, value2)

        if case .right(let tuple) = result {
            XCTAssertEqual(tuple.0, 5)
            XCTAssertEqual(tuple.1, "test")
        } else {
            XCTFail("Expected right value")
        }

        let left1: Either<String, Int> = .left("error")
        let leftResult = Either<String, (Int, String)>.zip(left1, value2)
        if case .left(let error) = leftResult {
            XCTAssertEqual(error, "error")
        } else {
            XCTFail("Expected left value")
        }
    }

    // MARK: - Applicative Laws

    func testApplicativeIdentityLaw() {
        // pure id <*> v = v
        let value: Either<String, Int> = .right(5)
        let identity: Either<String, (Int) -> Int> = .right({ $0 })
        let result = identity <*> value
        XCTAssertEqual(result, value)
    }

    func testApplicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
        let u: Either<String, (Int) -> String> = .right({ "\($0)" })
        let v: Either<String, (Int) -> Int> = .right({ $0 * 2 })
        let w: Either<String, Int> = .right(5)

        // Left side: compose functions then apply to w
        let composeFn: (@escaping (Int) -> String, @escaping (Int) -> Int) -> (Int) -> String = { f, g in
            { x in f(g(x)) }
        }
        let composed = Either<String, (Int) -> String>.liftA2(composeFn)(u, v)
        let left = composed <*> w

        // Right side: apply v to w, then apply u
        let vw = v <*> w
        let right = u <*> vw

        XCTAssertEqual(left, right)
    }

    func testApplicativeHomomorphismLaw() {
        // pure f <*> pure x = pure (f x)
        let f: (Int) -> Int = { $0 * 2 }
        let x = 5

        let pureF: Either<String, (Int) -> Int> = .right(f)
        let pureX: Either<String, Int> = .right(x)
        let left = pureF <*> pureX
        let right: Either<String, Int> = .right(f(x))

        XCTAssertEqual(left, right)
    }

    func testApplicativeInterchangeLaw() {
        // u <*> pure y = pure ($ y) <*> u
        let u: Either<String, (Int) -> Int> = .right({ $0 * 2 })
        let y = 5

        let pureY: Either<String, Int> = .right(y)
        let left = u <*> pureY

        let applyTo: (@escaping (Int) -> Int) -> Int = { fn in fn(y) }
        let pureApply: Either<String, (@escaping (Int) -> Int) -> Int> = .right(applyTo)
        let right = pureApply <*> u

        XCTAssertEqual(left, right)
    }

    // MARK: - Applicative Operators

    func testApplyOperator() {
        let fn: Either<String, (Int) -> Int> = .right({ $0 * 2 })
        let value: Either<String, Int> = .right(5)
        let result = fn <*> value
        XCTAssertEqual(result, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = fn <*> left
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testSequenceRight() {
        let value1: Either<String, Int> = .right(5)
        let value2: Either<String, Int> = .right(10)
        let result = value1 *> value2
        XCTAssertEqual(result, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left *> value2
        XCTAssertEqual(leftResult, .left("error"))

        let leftResult2 = value1 *> left
        XCTAssertEqual(leftResult2, .left("error"))
    }

    func testSequenceLeft() {
        let value1: Either<String, Int> = .right(5)
        let value2: Either<String, Int> = .right(10)
        let result = value1 <* value2
        XCTAssertEqual(result, .right(5))

        let left: Either<String, Int> = .left("error")
        let leftResult = left <* value2
        XCTAssertEqual(leftResult, .left("error"))

        let leftResult2 = value1 <* left
        XCTAssertEqual(leftResult2, .left("error"))
    }
}
