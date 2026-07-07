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
        let result = applyOptionalNonEmpty(fns, values)
        // cartesian: (+1)(1), (+1)(2), (*10)(1), (*10)(2)
        #expect(result?.toArray == [2, 3, 10, 20])
    }

    @Test func apply_fnsNil() {
        let fns: NonEmpty<@Sendable (Int) -> Int>? = nil
        let values: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        #expect(applyOptionalNonEmpty(fns, values) == nil)
    }

    @Test func apply_valuesNil() {
        let fns: NonEmpty<@Sendable (Int) -> Int>? = NonEmpty(head: { $0 + 1 })
        let values: NonEmpty<Int>? = nil
        #expect(applyOptionalNonEmpty(fns, values) == nil)
    }

    // MARK: - liftA2

    @Test func liftA2_bothPresent() {
        let result = liftA2OptionalNonEmpty(+)(NonEmpty(head: 1, tail: [2]), NonEmpty(head: 10, tail: [20]))
        #expect(result?.toArray == [11, 21, 12, 22])
    }

    @Test func liftA2_leftNil() {
        let lhs: NonEmpty<Int>? = nil
        let rhs: NonEmpty<Int>? = NonEmpty(head: 10)
        #expect(liftA2OptionalNonEmpty(+)(lhs, rhs) == nil)
    }

    @Test func liftA2_rightNil() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1)
        let rhs: NonEmpty<Int>? = nil
        #expect(liftA2OptionalNonEmpty(+)(lhs, rhs) == nil)
    }

    // MARK: - seqRight

    @Test func seqRight_bothPresent() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect(seqRightOptionalNonEmpty(lhs, rhs)?.toArray == ["x"])
    }

    @Test func seqRight_leftNil() {
        let lhs: NonEmpty<Int>? = nil
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect(seqRightOptionalNonEmpty(lhs, rhs) == nil)
    }

    @Test func seqRight_rightNil() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1)
        let rhs: NonEmpty<String>? = nil
        #expect(seqRightOptionalNonEmpty(lhs, rhs) == nil)
    }

    // MARK: - seqLeft

    @Test func seqLeft_bothPresent() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect(seqLeftOptionalNonEmpty(lhs, rhs)?.toArray == [1, 2])
    }

    @Test func seqLeft_leftNil() {
        let lhs: NonEmpty<Int>? = nil
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect(seqLeftOptionalNonEmpty(lhs, rhs) == nil)
    }

    @Test func seqLeft_rightNil() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1)
        let rhs: NonEmpty<String>? = nil
        #expect(seqLeftOptionalNonEmpty(lhs, rhs) == nil)
    }
}
