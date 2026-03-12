import XCTest
@testable import Either
import FP
@testable import EitherOperators
import Operators

final class EitherFunctorTests: XCTestCase {

    // MARK: - Basic Functor Tests

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
        let right: Either<String, Int> = .right(5)
        let rightResult = right.bimap({ $0.uppercased() }, { $0 * 2 })
        XCTAssertEqual(rightResult, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.bimap({ $0.uppercased() }, { $0 * 2 })
        XCTAssertEqual(leftResult, .left("ERROR"))
    }

    // MARK: - Functor Laws

    func testFunctorIdentityLaw() {
        // fmap id == id
        let right: Either<String, Int> = .right(5)
        let left: Either<String, Int> = .left("error")

        let identity: (Int) -> Int = { $0 }

        XCTAssertEqual(right.mapRight(identity), right)
        XCTAssertEqual(left.mapRight(identity), left)
    }

    func testFunctorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let value: Either<String, Int> = .right(5)

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        let composed = value.mapRight(compose(f, g))
        let separate = value.mapRight(f).mapRight(g)

        XCTAssertEqual(composed, separate)
    }

    // MARK: - Functor Operators

    func testFmapOperator() {
        let value: Either<String, Int> = .right(5)
        let result = { $0 * 2 } <£> value
        XCTAssertEqual(result, .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = { $0 * 2 } <£> left
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testMapReplaceOperator() {
        let value: Either<String, Int> = .right(5)
        let result = value £> 99
        XCTAssertEqual(result, .right(99))

        let left: Either<String, Int> = .left("error")
        let leftResult = left £> 99
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testMapReplaceFlippedOperator() {
        let value: Either<String, Int> = .right(5)
        let result = 42 <£ value
        XCTAssertEqual(result, .right(42))

        let left: Either<String, Int> = .left("error")
        let leftResult = 42 <£ left
        XCTAssertEqual(leftResult, .left("error"))
    }

    func testFlippedFmapOperator() {
        let value: Either<String, Int> = .right(5)
        let result = value <&> { $0 * 2 }
        XCTAssertEqual(result, .right(10))
    }
}
