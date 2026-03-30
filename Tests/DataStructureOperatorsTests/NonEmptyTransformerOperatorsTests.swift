import DataStructure
import DataStructureOperators
import Testing
import CoreFPOperators

private enum TestError: Error, Equatable { case bad(String) }

@Suite struct NonEmptyTransformerOperatorsTests {
    // MARK: - NonEmpty<A?> — <£^> (fn left)

    @Test func nonEmptyTOptional_fmapOperator_forward() {
        let ne = NonEmpty<Int?>(head: 1, tail: [nil, 3])
        let result = { $0 * 10 } <£^> ne
        #expect(result.toArray == [Optional(10), nil, Optional(30)])
    }

    // MARK: - NonEmpty<A?> — <&^> (container left)

    @Test func nonEmptyTOptional_fmapOperator_flipped() {
        let ne = NonEmpty<Int?>(head: 2, tail: [nil])
        let result = ne <&^> { $0 + 1 }
        #expect(result.toArray == [Optional(3), nil])
    }

    // MARK: - NonEmpty<Result<A, E>> — <£^> (fn left)

    @Test func nonEmptyTResult_fmapOperator_forward() {
        let ne = NonEmpty<Result<Int, TestError>>(
            head: .success(1),
            tail: [.failure(.bad("err")), .success(3)]
        )
        let result = { $0 * 10 } <£^> ne
        #expect(result.toArray == [.success(10), .failure(.bad("err")), .success(30)])
    }

    // MARK: - NonEmpty<Result<A, E>> — <&^> (container left)

    @Test func nonEmptyTResult_fmapOperator_flipped() {
        let ne = NonEmpty<Result<Int, TestError>>(
            head: .success(5),
            tail: [.failure(.bad("bad"))]
        )
        let result = ne <&^> { $0 * 2 }
        #expect(result.toArray == [.success(10), .failure(.bad("bad"))])
    }
}
