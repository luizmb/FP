import XCTest
@testable import FP
@testable import Operators

final class OptionalFunctorTests: XCTestCase {

    // MARK: - Basic Functor Tests

    func testFmap() {
        let value: Int? = 5
        let result = value.map { $0 * 2 }
        XCTAssertEqual(result, 10)

        let none: Int? = nil
        let noneResult = none.map { $0 * 2 }
        XCTAssertNil(noneResult)
    }

    func testCurriedFmap() {
        let double: (Int) -> Int = { $0 * 2 }
        let fmap = Optional<Int>.fmap(double)

        XCTAssertEqual(fmap(5), 10)
        XCTAssertNil(fmap(nil))
    }

    // MARK: - Functor Laws

    func testFunctorIdentityLaw() {
        // fmap id == id
        let value: Int? = 5
        let none: Int? = nil

        let identity: (Int) -> Int = { $0 }

        XCTAssertEqual(value.map(identity), value)
        XCTAssertEqual(none.map(identity), none)
    }

    func testFunctorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let value: Int? = 5

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        let composed = value.map(compose(f, g))
        let separate = value.map(f).map(g)

        XCTAssertEqual(composed, separate)
    }

    // MARK: - Functor Operators

    func testFmapOperator() {
        let value: Int? = 5
        let result = { $0 * 2 } <£> value
        XCTAssertEqual(result, 10)

        let none: Int? = nil
        let noneResult = { $0 * 2 } <£> none
        XCTAssertNil(noneResult)
    }

    func testMapReplaceOperator() {
        let value: Int? = 5
        let result = value £> 99
        XCTAssertEqual(result, 99)

        let none: Int? = nil
        let noneResult = none £> 99
        XCTAssertNil(noneResult)
    }

    func testMapReplaceFlippedOperator() {
        let value: Int? = 5
        let result = 42 <£ value
        XCTAssertEqual(result, 42)

        let none: Int? = nil
        let noneResult = 42 <£ none
        XCTAssertNil(noneResult)
    }

    func testFlippedFmapOperator() {
        let value: Int? = 5
        let result = value <&> { $0 * 2 }
        XCTAssertEqual(result, 10)

        let none: Int? = nil
        let noneResult = none <&> { $0 * 2 }
        XCTAssertNil(noneResult)
    }
}
