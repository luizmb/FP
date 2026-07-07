// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ZipperOperatorsTests {
    private let single = Zipper(focus: 1)
    private let middle = Zipper(left: [2, 1], focus: 3, right: [4, 5])

    // MARK: - <£> (fn left)

    @Test func fmapOperator_forward() {
        let result = { $0 * 10 } <£> middle
        #expect(result.toArray() == [10, 20, 30, 40, 50])
    }

    // MARK: - <&> (container left)

    @Test func fmapOperator_flipped() {
        let result = middle <&> { $0 + 1 }
        #expect(result.toArray() == [2, 3, 4, 5, 6])
    }

    // MARK: - £> (replace, container left)

    @Test func replaceOperator_forward() {
        let result = middle £> 0
        #expect(result.toArray() == [0, 0, 0, 0, 0])
    }

    // MARK: - <£ (replace, value left)

    @Test func replaceOperator_flipped() {
        let result = 99 <£ middle
        #expect(result.toArray() == [99, 99, 99, 99, 99])
    }

    // MARK: - Functor laws via operators

    @Test func functorLaw_identity() {
        let result = id <£> middle
        #expect(result == middle)
    }

    @Test func functorLaw_composition() {
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> Int = { $0 * 2 }
        let lhs = compose(f, g) <£> middle
        let rhs = g <£> (f <£> middle)
        #expect(lhs == rhs)
    }

    // MARK: - ->> (extend, container left)

    @Test func extendOperator_forward() {
        let sums = middle ->> { z in z.left.reduce(0, +) + z.focus + z.right.reduce(0, +) }
        #expect(sums.toArray() == [15, 15, 15, 15, 15])
    }

    @Test func extendOperator_forward_singleElement() {
        let doubled = single ->> { $0.focus * 2 }
        #expect(doubled.toArray() == [2])
    }

    // MARK: - <<- (extend, fn left)

    @Test func extendOperator_flipped() {
        let fn: @Sendable (Zipper<Int>) -> Int = { $0.focus * 100 }
        let result = fn <<- middle
        #expect(result == (middle ->> fn))
    }

    // MARK: - Comonad laws via operators

    @Test func comonadLaw_extractDuplicate() {
        #expect(extract(duplicate(middle)) == middle)
    }

    @Test func comonadLaw_mapExtractDuplicate() {
        let result = get(\Zipper<Int>.extract) <£> duplicate(middle)
        #expect(result == middle)
        #expect(result.toArray() == middle.toArray())
    }
}
