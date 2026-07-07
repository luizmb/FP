// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct NonEmptyComonadOperatorsTests {
    private let three = NonEmpty(head: 1, tail: [2, 3])

    // MARK: - ->>

    @Test func extendOperator() {
        let result = three ->> \.count
        #expect(result.toArray == [3, 2, 1])
    }

    @Test func extendOperatorChained() {
        // Left-associative: (ne ->> f) ->> g
        let result = three ->> \.count ->> \.count
        // first step: NonEmpty(3, [2, 1]); second: NonEmpty(3, [2, 1]) (same shape/count)
        #expect(result.toArray == [3, 2, 1])
    }

    // MARK: - <<-

    @Test func flippedExtendOperator() {
        let result: NonEmpty<Int> = \.count <<- three
        #expect(result.toArray == [3, 2, 1])
    }

    // MARK: - Comonad law via operators

    @Test func comonadLawExtendExtractOperator() {
        let result = three ->> { extract($0) }
        #expect(result == three)
    }
}
