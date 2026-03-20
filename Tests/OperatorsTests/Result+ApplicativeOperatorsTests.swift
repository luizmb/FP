import XCTest
@testable import FP
@testable import Operators

final class ResultApplicativeTests: XCTestCase {

    enum TestError: Error, Equatable {
        case error1
        case error2
    }

    // MARK: - Basic Applicative Tests

    func testApply() {
        let fn: Result<(Int) -> Int, TestError> = .success({ $0 * 2 })
        let value: Result<Int, TestError> = .success(5)
        let result = fn <*> value
        XCTAssertEqual(try? result.get(), 10)

        let failureFn: Result<(Int) -> Int, TestError> = .failure(.error1)
        let failureResult = failureFn <*> value
        XCTAssertThrowsError(try failureResult.get())

        let failureValue: Result<Int, TestError> = .failure(.error2)
        let failureValueResult = fn <*> failureValue
        XCTAssertThrowsError(try failureValueResult.get())
    }

    func testLiftA2() {
        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted = Result<Int, TestError>.liftA2(add)

        let value1: Result<Int, TestError> = .success(5)
        let value2: Result<Int, TestError> = .success(3)
        XCTAssertEqual(try? lifted(value1, value2).get(), 8)

        let failure1: Result<Int, TestError> = .failure(.error1)
        XCTAssertThrowsError(try lifted(failure1, value2).get())

        let failure2: Result<Int, TestError> = .failure(.error2)
        XCTAssertThrowsError(try lifted(value1, failure2).get())
    }

    func testZip() {
        let value1: Result<Int, TestError> = .success(5)
        let value2: Result<String, TestError> = .success("test")
        let result = Result<(Int, String), TestError>.zip(value1, value2)

        if case .success(let tuple) = result {
            XCTAssertEqual(tuple.0, 5)
            XCTAssertEqual(tuple.1, "test")
        } else {
            XCTFail("Expected success value")
        }

        let failure1: Result<Int, TestError> = .failure(.error1)
        let failureResult = Result<(Int, String), TestError>.zip(failure1, value2)
        XCTAssertThrowsError(try failureResult.get())
    }

    // MARK: - Applicative Laws

    func testApplicativeIdentityLaw() {
        // pure id <*> v = v
        let value: Result<Int, TestError> = .success(5)
        let identity: Result<(Int) -> Int, TestError> = .success({ $0 })
        let result = identity <*> value
        XCTAssertEqual(try? result.get(), try? value.get())
    }

    func testApplicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
        let u: Result<(Int) -> String, TestError> = .success({ "\($0)" })
        let v: Result<(Int) -> Int, TestError> = .success({ $0 * 2 })
        let w: Result<Int, TestError> = .success(5)

        // Left side: compose functions then apply to w
        let composeFn: (@escaping (Int) -> String, @escaping (Int) -> Int) -> (Int) -> String = { f, g in
            { x in f(g(x)) }
        }
        let composed = Result<(Int) -> String, TestError>.liftA2(composeFn)(u, v)
        let left = composed <*> w

        // Right side: apply v to w, then apply u
        let vw = v <*> w
        let right = u <*> vw

        XCTAssertEqual(try? left.get(), try? right.get())
    }

    func testApplicativeHomomorphismLaw() {
        // pure f <*> pure x = pure (f x)
        let f: (Int) -> Int = { $0 * 2 }
        let x = 5

        let pureF: Result<(Int) -> Int, TestError> = .success(f)
        let pureX: Result<Int, TestError> = .success(x)
        let left = pureF <*> pureX
        let right: Result<Int, TestError> = .success(f(x))

        XCTAssertEqual(try? left.get(), try? right.get())
    }

    func testApplicativeInterchangeLaw() {
        // u <*> pure y = pure ($ y) <*> u
        let u: Result<(Int) -> Int, TestError> = .success({ $0 * 2 })
        let y = 5

        let pureY: Result<Int, TestError> = .success(y)
        let left = u <*> pureY

        let applyTo: (@escaping (Int) -> Int) -> Int = { fn in fn(y) }
        let pureApply: Result<(@escaping (Int) -> Int) -> Int, TestError> = .success(applyTo)
        let right = pureApply <*> u

        XCTAssertEqual(try? left.get(), try? right.get())
    }

    // MARK: - Applicative Operators

    func testApplyOperator() {
        let fn: Result<(Int) -> Int, TestError> = .success({ $0 * 2 })
        let value: Result<Int, TestError> = .success(5)
        let result = fn <*> value
        XCTAssertEqual(try? result.get(), 10)

        let failure: Result<Int, TestError> = .failure(.error1)
        let failureResult = fn <*> failure
        XCTAssertThrowsError(try failureResult.get())
    }

    func testSequenceRight() {
        let value1: Result<Int, TestError> = .success(5)
        let value2: Result<Int, TestError> = .success(10)
        let result = value1 *> value2
        XCTAssertEqual(try? result.get(), 10)

        let failure: Result<Int, TestError> = .failure(.error1)
        XCTAssertThrowsError(try (failure *> value2).get())
        XCTAssertThrowsError(try (value1 *> failure).get())
    }

    func testSequenceLeft() {
        let value1: Result<Int, TestError> = .success(5)
        let value2: Result<Int, TestError> = .success(10)
        let result = value1 <* value2
        XCTAssertEqual(try? result.get(), 5)

        let failure: Result<Int, TestError> = .failure(.error1)
        XCTAssertThrowsError(try (failure <* value2).get())
        XCTAssertThrowsError(try (value1 <* failure).get())
    }
}
