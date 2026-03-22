import Testing
@testable import Core
@testable import CoreOperators

@Suite struct ArrayOperatorsTests {

    // MARK: - Functor Operators

    @Test func fmapOperator() {
        let array = [1, 2, 3]
        let result = { $0 * 2 } <£> array
        #expect(result == [2, 4, 6])
    }

    @Test func mapReplaceOperator() {
        let array = [1, 2, 3]
        let result = array £> "x"
        #expect(result == ["x", "x", "x"])
    }

    @Test func mapReplaceOperatorFlipped() {
        let array = [1, 2, 3]
        let result = "x" <£ array
        #expect(result == ["x", "x", "x"])
    }

    @Test func flippedFmap() {
        let array = [1, 2, 3]
        let result = array <&> { $0 * 2 }
        #expect(result == [2, 4, 6])
    }

    // MARK: - Applicative Operators

    @Test func applyOperator() {
        let functions: [(Int) -> Int] = [{ $0 * 2 }, { $0 + 10 }]
        let values = [1, 2, 3]

        let result = functions <*> values
        #expect(result == [2, 4, 6, 11, 12, 13])
    }

    @Test func sequenceLeft() {
        let arr1 = [1, 2]
        let arr2 = [3, 4]

        let result = arr1 *> arr2
        #expect(result == [3, 4, 3, 4])
    }

    @Test func sequenceRight() {
        let arr1 = [1, 2]
        let arr2 = [3, 4]

        let result = arr1 <* arr2
        #expect(result == [1, 1, 2, 2])
    }

    // MARK: - Monad Operators

    @Test func bindOperator() {
        let array = [1, 2, 3]
        let result = array >>- { [$0, $0 * 2] }
        #expect(result == [1, 2, 2, 4, 3, 6])
    }

    @Test func flippedBindOperator() {
        let fn: (Int) -> [Int] = { [$0, $0 * 2] }
        let array = [1, 2, 3]
        let result = fn -<< array
        #expect(result == [1, 2, 2, 4, 3, 6])
    }

    @Test func kleisliOperator() {
        let duplicate: (Int) -> [Int] = { [$0, $0] }
        let double: (Int) -> [Int] = { [$0 * 2] }

        let composed = duplicate >=> double
        #expect(composed(5) == [10, 10])
    }

    // MARK: - Alternative Operators

    @Test func alternativeOperator() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        #expect((arr1 <|> arr2) == [1, 2, 3, 4, 5, 6])
    }

    @Test func appendOperator() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        #expect((arr1 ++ arr2) == [1, 2, 3, 4, 5, 6])
    }
}
