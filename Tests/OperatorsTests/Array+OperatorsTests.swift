import XCTest
@testable import FP
@testable import Operators

final class ArrayOperatorsTests: XCTestCase {

    // MARK: - Functor Operators

    func testFmapOperator() {
        let array = [1, 2, 3]
        let result = { $0 * 2 } <£> array
        XCTAssertEqual(result, [2, 4, 6])
    }

    func testMapReplaceOperator() {
        let array = [1, 2, 3]
        let result = array £> "x"
        XCTAssertEqual(result, ["x", "x", "x"])
    }

    func testMapReplaceOperatorFlipped() {
        let array = [1, 2, 3]
        let result = "x" <£ array
        XCTAssertEqual(result, ["x", "x", "x"])
    }

    func testFlippedFmap() {
        let array = [1, 2, 3]
        let result = array <&> { $0 * 2 }
        XCTAssertEqual(result, [2, 4, 6])
    }

    // MARK: - Applicative Operators

    func testApplyOperator() {
        let functions: [(Int) -> Int] = [{ $0 * 2 }, { $0 + 10 }]
        let values = [1, 2, 3]

        let result = functions <*> values
        XCTAssertEqual(result, [2, 4, 6, 11, 12, 13])
    }

    func testSequenceLeft() {
        let arr1 = [1, 2]
        let arr2 = [3, 4]

        let result = arr1 *> arr2
        XCTAssertEqual(result, [3, 4, 3, 4])
    }

    func testSequenceRight() {
        let arr1 = [1, 2]
        let arr2 = [3, 4]

        let result = arr1 <* arr2
        XCTAssertEqual(result, [1, 1, 2, 2])
    }

    // MARK: - Monad Operators

    func testBindOperator() {
        let array = [1, 2, 3]
        let result = array >>- { [$0, $0 * 2] }
        XCTAssertEqual(result, [1, 2, 2, 4, 3, 6])
    }

    func testFlippedBindOperator() {
        let fn: (Int) -> [Int] = { [$0, $0 * 2] }
        let array = [1, 2, 3]
        let result = fn -<< array
        XCTAssertEqual(result, [1, 2, 2, 4, 3, 6])
    }

    func testKleisliOperator() {
        let duplicate: (Int) -> [Int] = { [$0, $0] }
        let double: (Int) -> [Int] = { [$0 * 2] }

        let composed = duplicate >=> double
        XCTAssertEqual(composed(5), [10, 10])
    }

    // MARK: - Alternative Operators

    func testAlternativeOperator() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        XCTAssertEqual(arr1 <|> arr2, [1, 2, 3, 4, 5, 6])
    }

    func testAppendOperator() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        XCTAssertEqual(arr1 ++ arr2, [1, 2, 3, 4, 5, 6])
    }
}
