import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ValidationTNonEmptyOperatorsTests {
    @Test func fmapOperator_forward_success() {
        let v: Validation<String, NonEmpty<Int>> = .success(NonEmpty(head: 1, tail: [2, 3]))
        let result = { $0 * 10 } <£^> v
        #expect(result == .success(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func fmapOperator_forward_failure() {
        let v: Validation<String, NonEmpty<Int>> = .failure("err")
        let result = { $0 * 10 } <£^> v
        #expect(result == .failure("err"))
    }

    @Test func fmapOperator_flipped() {
        let v: Validation<String, NonEmpty<Int>> = .success(NonEmpty(head: 5))
        let result = v <&^> { $0 + 1 }
        #expect(result == .success(NonEmpty(head: 6)))
    }
}
