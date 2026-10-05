// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?> = NonEmpty<Optional<A>>

@Suite struct NonEmptyTOptionalApplicativeTests {
    // MARK: - apply

    @Test func apply_cartesianProduct() {
        let fns = NonEmpty<(@Sendable (Int) -> Int)?>(head: { $0 + 1 }, tail: [nil])
        let values = NonEmpty<Int?>(head: 1, tail: [2])
        let result = NonEmptyTOptional.apply(fns.nonEmptyT, values.nonEmptyT).rawValue
        // f=(+1): [2, 3]; f=nil: [nil] (MaybeT NonEmpty, <*> = ap)
        #expect(result.toArray == [Optional(2), Optional(3), nil])
    }

    // MARK: - liftA2

    @Test func liftA2_allPresent() {
        let result = NonEmptyTOptional<Int>.liftA2(+)(
            NonEmptyTOptional(NonEmpty(head: 1, tail: [2])),
            NonEmptyTOptional(NonEmpty(head: 10, tail: [20]))
        ).rawValue
        #expect(result.toArray == [Optional(11), Optional(21), Optional(12), Optional(22)])
    }

    @Test func liftA2_someNil() {
        let a = NonEmpty<Int?>(head: 1, tail: [nil])
        let b = NonEmpty<Int?>(head: 10)
        let result = NonEmptyTOptional.liftA2(+)(a.nonEmptyT, b.nonEmptyT).rawValue
        #expect(result.toArray == [Optional(11), nil])
    }

    // MARK: - seqRight

    @Test func seqRight_combinesInnerOptionals() {
        let lhs = NonEmpty<Int?>(head: 1, tail: [nil])
        let rhs = NonEmpty<String?>(head: "x")
        let result = lhs.nonEmptyT.seqRight(rhs.nonEmptyT).rawValue
        #expect(result.toArray == [Optional("x"), nil])
    }

    // MARK: - seqLeft

    @Test func seqLeft_combinesInnerOptionals() {
        let lhs = NonEmpty<Int?>(head: 1, tail: [nil])
        let rhs = NonEmpty<String?>(head: "x")
        let result = lhs.nonEmptyT.seqLeft(rhs.nonEmptyT).rawValue
        #expect(result.toArray == [Optional(1), nil])
    }
}
