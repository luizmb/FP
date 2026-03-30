import CoreFP
import DataStructure
import DataStructureOperators
import Testing
import CoreFPOperators

@Suite struct NonEmptyFunctorOperatorsTests {
    private let three = NonEmpty(head: 1, tail: [2, 3])

    // MARK: - <£> (fn left)

    @Test func fmapOperator_forward() {
        let result = { $0 * 10 } <£> three
        #expect(result.toArray == [10, 20, 30])
    }

    // MARK: - <&> (container left)

    @Test func fmapOperator_flipped() {
        let result = three <&> { $0 + 1 }
        #expect(result.toArray == [2, 3, 4])
    }

    // MARK: - £> (replace, container left)

    @Test func replaceOperator_forward() {
        let result = three £> 0
        #expect(result.toArray == [0, 0, 0])
    }

    // MARK: - <£ (replace, value left)

    @Test func replaceOperator_flipped() {
        let result = 99 <£ three
        #expect(result.toArray == [99, 99, 99])
    }

    // MARK: - Functor laws via operators

    @Test func functorLaw_identity() {
        let result = id <£> three
        #expect(result == three)
    }

    @Test func functorLaw_composition() {
        let f: (Int) -> Int = { $0 + 1 }
        let g: (Int) -> Int = { $0 * 2 }
        let lhs = compose(f, g) <£> three
        let rhs = g <£> (f <£> three)
        #expect(lhs == rhs)
    }
}
