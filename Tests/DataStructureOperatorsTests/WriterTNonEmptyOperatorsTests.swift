import DataStructureOperators
import DataStructure
import Testing
import CoreFP
import CoreFPOperators

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
}
