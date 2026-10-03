// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTNonEmptyOperatorsTests {
    @Test func fmapOperator_forward() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2, 3]), ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == NonEmpty(head: 2, tail: [4, 6]))
        #expect(result.log == ["log"])
    }

    @Test func fmapOperator_flipped() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 5), ["entry"])
        let result = w <&^> { $0 + 1 }
        #expect(result.value == NonEmpty(head: 6))
        #expect(result.log == ["entry"])
    }

    // MARK: - Applicative operators

    @Test func applyOperator() {
        let wf = Writer<[String], NonEmpty<@Sendable (Int) -> Int>>(NonEmpty(head: { $0 + 10 }), ["fn"])
        let wa = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2]), ["val"])
        let result = wf <*> wa
        #expect(result.value == NonEmpty(head: 11, tail: [12]))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRightOperator() {
        let lhs = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1), ["lhs"])
        let rhs = Writer<[String], NonEmpty<String>>(NonEmpty(head: "b"), ["rhs"])
        let result = lhs *> rhs
        #expect(result.value == NonEmpty(head: "b"))
        #expect(result.log == ["lhs", "rhs"])
    }

    @Test func seqLeftOperator() {
        let lhs = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1), ["lhs"])
        let rhs = Writer<[String], NonEmpty<String>>(NonEmpty(head: "b"), ["rhs"])
        let result = lhs <* rhs
        #expect(result.value == NonEmpty(head: 1))
        #expect(result.log == ["lhs", "rhs"])
    }
}
