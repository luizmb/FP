// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTNonEmptyOperatorsTests {
    // MARK: - Applicative operators

    @Test func applyOperator() {
        let wf = Writer<[String], NonEmpty<@Sendable (Int) -> Int>>(NonEmpty(head: { $0 + 10 }), ["fn"])
        let wa = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2]), ["val"])
        let result = (wf.writerT <*> wa.writerT).rawValue
        #expect(result.value == NonEmpty(head: 11, tail: [12]))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRightOperator() {
        let lhs = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1), ["lhs"])
        let rhs = Writer<[String], NonEmpty<String>>(NonEmpty(head: "b"), ["rhs"])
        let result = (lhs.writerT *> rhs.writerT).rawValue
        #expect(result.value == NonEmpty(head: "b"))
        #expect(result.log == ["lhs", "rhs"])
    }

    @Test func seqLeftOperator() {
        let lhs = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1), ["lhs"])
        let rhs = Writer<[String], NonEmpty<String>>(NonEmpty(head: "b"), ["rhs"])
        let result = (lhs.writerT <* rhs.writerT).rawValue
        #expect(result.value == NonEmpty(head: 1))
        #expect(result.log == ["lhs", "rhs"])
    }
}
