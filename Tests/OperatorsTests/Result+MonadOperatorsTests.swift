import XCTest
@testable import FP
@testable import Operators

final class ResultMonadTests: XCTestCase {

    func testBind() {
        let value: Result<Int, NSError> = .success(5)
        let result = value >>- { x in .success(x * 2) }
        XCTAssertEqual(try? result.get(), 10)

        let error: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
        let errorResult = error >>- { x in .success(x * 2) }
        XCTAssertThrowsError(try errorResult.get())
    }

    func testFlippedBind() {
        let double: (Int) -> Result<Int, NSError> = { .success($0 * 2) }
        let value: Result<Int, NSError> = .success(5)
        let result = double -<< value
        XCTAssertEqual(try? result.get(), 10)
    }

    func testKleisliComposition() {
        let safe: (Int) -> Result<Int, NSError> = { $0 > 0 ? .success($0) : .failure(NSError(domain: "test", code: 1)) }
        let double: (Int) -> Result<Int, NSError> = { .success($0 * 2) }

        let composed = safe >=> double
        XCTAssertEqual(try? composed(5).get(), 10)
        XCTAssertThrowsError(try composed(-1).get())
    }

    func testFlippedFmap() {
        let value: Result<Int, NSError> = .success(5)
        let result = value <&> { $0 * 2 }
        XCTAssertEqual(try? result.get(), 10)
    }

    func testAlternative() {
        let success: Result<Int, NSError> = .success(5)
        let failure: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
        let alternative: Result<Int, NSError> = .success(10)

        XCTAssertEqual(try? (success <|> alternative).get(), 5)
        XCTAssertEqual(try? (failure <|> alternative).get(), 10)
    }

    func testVoid() {
        let success: Result<Int, NSError> = .success(5)
        let voided = success.void()
        XCTAssertNoThrow(try voided.get())
    }
}
