// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTNonEmptyOperatorsTests {
    @Test func fmapOperator_forward() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1, tail: [2, 3]))
        let result = { $0 * 2 } <£^> s
        #expect(result.eval(0) == NonEmpty(head: 2, tail: [4, 6]))
    }

    @Test func fmapOperator_flipped() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 5))
        let result = s <&^> { $0 + 1 }
        #expect(result.eval(0) == NonEmpty(head: 6))
    }

    // MARK: - Applicative

    @Test func apply() {
        let sf = Stateful<Int, NonEmpty<@Sendable (Int) -> String>>.pure(NonEmpty(head: { "\($0)" }))
        let sa = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 9, tail: [10]))
        let result = sf <*> sa
        #expect(result.eval(0) == NonEmpty(head: "9", tail: ["10"]))
    }

    @Test func seqRight() {
        let lhs = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1))
        let rhs = Stateful<Int, NonEmpty<String>>.pure(NonEmpty(head: "b"))
        let result = lhs *> rhs
        #expect(result.eval(0) == NonEmpty(head: "b"))
    }

    @Test func seqLeft() {
        let lhs = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1))
        let rhs = Stateful<Int, NonEmpty<String>>.pure(NonEmpty(head: "b"))
        let result = lhs <* rhs
        #expect(result.eval(0) == NonEmpty(head: 1))
    }
}
