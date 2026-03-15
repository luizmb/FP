import XCTest
@testable import FP
@testable import Operators

final class OptionalApplicativeTests: XCTestCase {

    // MARK: - Basic Applicative Tests

    func testApply() {
        let fn: ((Int) -> Int)? = { $0 * 2 }
        let value: Int? = 5
        let result = fn <*> value
        XCTAssertEqual(result, 10)

        let noneFn: ((Int) -> Int)? = nil
        let noneResult = noneFn <*> value
        XCTAssertNil(noneResult)

        let noneValue: Int? = nil
        let noneValueResult = fn <*> noneValue
        XCTAssertNil(noneValueResult)
    }

    func testLiftA2() {
        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted = Optional<Int>.liftA2(add)

        XCTAssertEqual(lifted(5, 3), 8)
        XCTAssertNil(lifted(nil, 3))
        XCTAssertNil(lifted(5, nil))
        XCTAssertNil(lifted(nil, nil))
    }

    func testZip() {
        let value1: Int? = 5
        let value2: String? = "test"
        let result = Optional<(Int, String)>.zip(value1, value2)

        if let tuple = result {
            XCTAssertEqual(tuple.0, 5)
            XCTAssertEqual(tuple.1, "test")
        } else {
            XCTFail("Expected some value")
        }

        let none1: Int? = nil
        XCTAssertNil(Optional<(Int, String)>.zip(none1, value2))
        XCTAssertNil(Optional<(Int, String)>.zip(value1, nil))
    }

    // MARK: - Applicative Laws

    func testApplicativeIdentityLaw() {
        // pure id <*> v = v
        let value: Int? = 5
        let identity: ((Int) -> Int)? = { $0 }
        let result = identity <*> value
        XCTAssertEqual(result, value)
    }

    func testApplicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
        let u: ((Int) -> String)? = { "\($0)" }
        let v: ((Int) -> Int)? = { $0 * 2 }
        let w: Int? = 5

        // Left side: compose functions then apply to w
        let composeFn: (@escaping (Int) -> String, @escaping (Int) -> Int) -> (Int) -> String = { f, g in
            { x in f(g(x)) }
        }
        let composed = Optional<(Int) -> String>.liftA2(composeFn)(u, v)
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

        let pureF: ((Int) -> Int)? = .some(f)
        let pureX: Int? = .some(x)
        let left = pureF <*> pureX
        let right: Int? = .some(f(x))

        XCTAssertEqual(left, right)
    }

    func testApplicativeInterchangeLaw() {
        // u <*> pure y = pure ($ y) <*> u
        let u: ((Int) -> Int)? = { $0 * 2 }
        let y = 5

        let pureY: Int? = .some(y)
        let left = u <*> pureY

        let applyTo: (@escaping (Int) -> Int) -> Int = { fn in fn(y) }
        let pureApply: ((@escaping (Int) -> Int) -> Int)? = .some(applyTo)
        let right = pureApply <*> u

        XCTAssertEqual(left, right)
    }

    // MARK: - Applicative Operators

    func testApplyOperator() {
        let fn: ((Int) -> Int)? = { $0 * 2 }
        let value: Int? = 5
        let result = fn <*> value
        XCTAssertEqual(result, 10)

        let none: Int? = nil
        let noneResult = fn <*> none
        XCTAssertNil(noneResult)
    }

    func testSequenceRight() {
        let value1: Int? = 5
        let value2: Int? = 10
        let result = value1 *> value2
        XCTAssertEqual(result, 10)

        let none: Int? = nil
        XCTAssertNil(none *> value2)
        XCTAssertNil(value1 *> none)
    }

    func testSequenceLeft() {
        let value1: Int? = 5
        let value2: Int? = 10
        let result = value1 <* value2
        XCTAssertEqual(result, 5)

        let none: Int? = nil
        XCTAssertNil(none <* value2)
        XCTAssertNil(value1 <* none)
    }
}
