import DataStructureOperators
import DataStructure
import Testing
import CoreFP
import CoreFPOperators

@Suite struct NonEmptyTEitherOperatorsTests {

    @Test func fmapOperator_forward() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.left("err"), .right(3)])
        let result = { $0 * 10 } <£^> ne
        #expect(result.toArray == [.right(10), .left("err"), .right(30)])
    }

    @Test func fmapOperator_flipped() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(2), tail: [.right(4)])
        let result = ne <&^> { $0 + 1 }
        #expect(result.toArray == [.right(3), .right(5)])
    }
}
