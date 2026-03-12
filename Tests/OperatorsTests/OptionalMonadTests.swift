import XCTest
@testable import FP
@testable import Operators

final class OptionalMonadTests: XCTestCase {

    func testBind() {
        let value: Int? = 5
        let result = value >>- { x in x > 0 ? .some(x * 2) : .none }
        XCTAssertEqual(result, 10)

        let none: Int? = nil
        let noneResult = none >>- { x in .some(x * 2) }
        XCTAssertNil(noneResult)
    }

    func testFlippedBind() {
        let double: (Int) -> Int? = { .some($0 * 2) }
        let result = double -<< 5
        XCTAssertEqual(result, 10)
    }

    func testKleisliComposition() {
        let safe: (Int) -> Int? = { $0 > 0 ? .some($0) : .none }
        let double: (Int) -> Int? = { .some($0 * 2) }

        let composed = safe >=> double
        XCTAssertEqual(composed(5), 10)
        XCTAssertNil(composed(-1))
    }

    func testFlippedFmap() {
        let value: Int? = 5
        let result = value <&> { $0 * 2 }
        XCTAssertEqual(result, 10)
    }

    func testAlternative() {
        let some: Int? = 5
        let none: Int? = nil

        XCTAssertEqual(some <|> 10, 5)
        XCTAssertEqual(none <|> 10, 10)
        XCTAssertNil(none <|> nil)
    }

    func testJoin() {
        let nested: Int?? = .some(.some(5))
        XCTAssertEqual(Optional<Int>.join(nested), 5)

        let nestedNone: Int?? = .some(.none)
        XCTAssertNil(Optional<Int>.join(nestedNone))

        let outerNone: Int?? = .none
        XCTAssertNil(Optional<Int>.join(outerNone))
    }

    func testFilter() {
        let value: Int? = 5
        XCTAssertEqual(value.filter { $0 > 3 }, 5)
        XCTAssertNil(value.filter { $0 > 10 })
    }
}
