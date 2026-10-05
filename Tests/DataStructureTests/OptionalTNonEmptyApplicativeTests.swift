// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

// OptionalTNonEmpty: outer = Optional, inner = NonEmpty
// Type: NonEmpty<A>? = Optional<NonEmpty<A>>

@Suite struct OptionalTNonEmptyApplicativeTests {
    // MARK: - apply

    @Test func apply_bothPresent() {
        let fns: NonEmpty<@Sendable (Int) -> Int>? = NonEmpty(head: { $0 + 1 }, tail: [{ $0 * 10 }])
        let values: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let result = OptionalTNonEmpty.apply(fns.optionalT, values.optionalT).rawValue
        // cartesian: (+1)(1), (+1)(2), (*10)(1), (*10)(2)
        #expect(result?.toArray == [2, 3, 10, 20])
    }

    @Test func apply_fnsNil() {
        let fns: NonEmpty<@Sendable (Int) -> Int>? = nil
        let values: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        #expect(OptionalTNonEmpty.apply(fns.optionalT, values.optionalT).rawValue == nil)
    }

    @Test func apply_valuesNil() {
        let fns: NonEmpty<@Sendable (Int) -> Int>? = NonEmpty(head: { $0 + 1 })
        let values: NonEmpty<Int>? = nil
        #expect(OptionalTNonEmpty.apply(fns.optionalT, values.optionalT).rawValue == nil)
    }

    // MARK: - liftA2

    @Test func liftA2_bothPresent() {
        let result = OptionalTNonEmpty<Int>.liftA2(+)(
            OptionalTNonEmpty(NonEmpty(head: 1, tail: [2])),
            OptionalTNonEmpty(NonEmpty(head: 10, tail: [20]))
        ).rawValue
        #expect(result?.toArray == [11, 21, 12, 22])
    }

    @Test func liftA2_leftNil() {
        let lhs: NonEmpty<Int>? = nil
        let rhs: NonEmpty<Int>? = NonEmpty(head: 10)
        #expect(OptionalTNonEmpty.liftA2(+)(lhs.optionalT, rhs.optionalT).rawValue == nil)
    }

    @Test func liftA2_rightNil() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1)
        let rhs: NonEmpty<Int>? = nil
        #expect(OptionalTNonEmpty.liftA2(+)(lhs.optionalT, rhs.optionalT).rawValue == nil)
    }

    // MARK: - seqRight

    @Test func seqRight_bothPresent() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect(lhs.optionalT.seqRight(rhs.optionalT).rawValue?.toArray == ["x"])
    }

    @Test func seqRight_leftNil() {
        let lhs: NonEmpty<Int>? = nil
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect(lhs.optionalT.seqRight(rhs.optionalT).rawValue == nil)
    }

    @Test func seqRight_rightNil() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1)
        let rhs: NonEmpty<String>? = nil
        #expect(lhs.optionalT.seqRight(rhs.optionalT).rawValue == nil)
    }

    // MARK: - seqLeft

    @Test func seqLeft_bothPresent() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect(lhs.optionalT.seqLeft(rhs.optionalT).rawValue?.toArray == [1, 2])
    }

    @Test func seqLeft_leftNil() {
        let lhs: NonEmpty<Int>? = nil
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect(lhs.optionalT.seqLeft(rhs.optionalT).rawValue == nil)
    }

    @Test func seqLeft_rightNil() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1)
        let rhs: NonEmpty<String>? = nil
        #expect(lhs.optionalT.seqLeft(rhs.optionalT).rawValue == nil)
    }
}
