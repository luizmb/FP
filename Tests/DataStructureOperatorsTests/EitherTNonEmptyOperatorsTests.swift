// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct EitherTNonEmptyOperatorsTests {
    @Test func fmapOperator_forward_right() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2, 3]))
        let result = { $0 * 10 } <£^> either
        #expect(result == .right(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func fmapOperator_forward_left() {
        let either: Either<String, NonEmpty<Int>> = .left("err")
        let result = { $0 * 10 } <£^> either
        #expect(result == .left("err"))
    }

    @Test func fmapOperator_flipped() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 5))
        let result = either <&^> { $0 + 1 }
        #expect(result == .right(NonEmpty(head: 6)))
    }
}
