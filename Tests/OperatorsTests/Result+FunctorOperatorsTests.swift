import XCTest
@testable import FP
@testable import Operators

final class ResultFunctorTests: XCTestCase {

    enum TestError: Error, Equatable {
        case test
    }

    // MARK: - Basic Functor Tests

    func testFmap() {
        let success: Result<Int, TestError> = .success(5)
        let result = success.map { $0 * 2 }
        XCTAssertEqual(try? result.get(), 10)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = failure.map { $0 * 2 }
        XCTAssertThrowsError(try failureResult.get())
    }

    func testCurriedFmap() {
        let double: (Int) -> Int = { $0 * 2 }
        let fmap = Result<Int, TestError>.fmap(double)

        let success: Result<Int, TestError> = .success(5)
        XCTAssertEqual(try? fmap(success).get(), 10)

        let failure: Result<Int, TestError> = .failure(.test)
        XCTAssertThrowsError(try fmap(failure).get())
    }

    // MARK: - Functor Laws

    func testFunctorIdentityLaw() {
        // fmap id == id
        let success: Result<Int, TestError> = .success(5)
        let failure: Result<Int, TestError> = .failure(.test)

        let identity: (Int) -> Int = { $0 }

        XCTAssertEqual(try? success.map(identity).get(), try? success.get())
        XCTAssertThrowsError(try failure.map(identity).get())
    }

    func testFunctorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let value: Result<Int, TestError> = .success(5)

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        let composed = value.map(compose(f, g))
        let separate = value.map(f).map(g)

        XCTAssertEqual(try? composed.get(), try? separate.get())
    }

    // MARK: - Functor Operators

    func testFmapOperator() {
        let success: Result<Int, TestError> = .success(5)
        let result = { $0 * 2 } <£> success
        XCTAssertEqual(try? result.get(), 10)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = { $0 * 2 } <£> failure
        XCTAssertThrowsError(try failureResult.get())
    }

    func testMapReplaceOperator() {
        let success: Result<Int, TestError> = .success(5)
        let result = success £> 99
        XCTAssertEqual(try? result.get(), 99)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = failure £> 99
        XCTAssertThrowsError(try failureResult.get())
    }

    func testMapReplaceFlippedOperator() {
        let success: Result<Int, TestError> = .success(5)
        let result = 42 <£ success
        XCTAssertEqual(try? result.get(), 42)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = 42 <£ failure
        XCTAssertThrowsError(try failureResult.get())
    }

    func testFlippedFmapOperator() {
        let success: Result<Int, TestError> = .success(5)
        let result = success <&> { $0 * 2 }
        XCTAssertEqual(try? result.get(), 10)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = failure <&> { $0 * 2 }
        XCTAssertThrowsError(try failureResult.get())
    }
}
