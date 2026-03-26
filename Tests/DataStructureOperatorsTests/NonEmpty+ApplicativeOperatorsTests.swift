import DataStructureOperators
import DataStructure
import Testing
import CoreFP
import CoreFPOperators

@Suite struct NonEmptyApplicativeOperatorsTests {

    // MARK: - <*> apply

    @Test func applyOperator_singleFunction() {
        let nf = NonEmpty<(Int) -> Int>(head: { $0 * 2 })
        let na = NonEmpty(head: 1, tail: [2, 3])
        #expect((nf <*> na).toArray == [2, 4, 6])
    }

    @Test func applyOperator_cartesian() {
        let nf = NonEmpty<(Int) -> Int>(head: { $0 + 1 }, tail: [{ $0 * 10 }])
        let na = NonEmpty(head: 1, tail: [2])
        #expect((nf <*> na).toArray == [2, 3, 10, 20])
    }

    // MARK: - *> seqRight

    @Test func seqRightOperator() {
        let a = NonEmpty(head: 1, tail: [2])
        let b = NonEmpty(head: "x", tail: ["y"])
        #expect((a *> b).toArray == ["x", "y", "x", "y"])
    }

    // MARK: - <* seqLeft

    @Test func seqLeftOperator() {
        let a = NonEmpty(head: 1, tail: [2])
        let b = NonEmpty(head: "x", tail: ["y"])
        #expect((a <* b).toArray == [1, 1, 2, 2])
    }
}
