// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?> = NonEmpty<Optional<A>>
// Transformer fmap is the named `mapT` (covered in DataStructureTests).

@Suite struct NonEmptyTOptionalOperatorsTests {
    // MARK: - Applicative: <*> / *> / <*

    @Test func applyOperator_cartesianProduct() {
        let fns = NonEmpty<(@Sendable (Int) -> Int)?>(head: { $0 + 1 }, tail: [nil])
        let values = NonEmpty<Int?>(head: 1, tail: [2])
        let result = (fns.nonEmptyT <*> values.nonEmptyT).rawValue
        // MaybeT NonEmpty: nil function yields a single nil (<*> = ap)
        #expect(result.toArray == [Optional(2), Optional(3), nil])
    }

    @Test func seqRightOperator() {
        let lhs = NonEmpty<Int?>(head: 1, tail: [nil])
        let rhs = NonEmpty<String?>(head: "x")
        #expect((lhs.nonEmptyT *> rhs.nonEmptyT).rawValue.toArray == [Optional("x"), nil])
    }

    @Test func seqLeftOperator() {
        let lhs = NonEmpty<Int?>(head: 1, tail: [nil])
        let rhs = NonEmpty<String?>(head: "x")
        #expect((lhs.nonEmptyT <* rhs.nonEmptyT).rawValue.toArray == [Optional(1), nil])
    }

    // MARK: - Monad: >>- / -<< / >=> / <=<

    @Test func bindOperator_forward() {
        let ne = NonEmpty<Int?>(head: 2, tail: [nil])
        let result = ne.nonEmptyT >>- { n in NonEmptyTOptional(NonEmpty<Int?>(head: n * 2)) }
        #expect(result.rawValue.toArray == [Optional(4), nil])
    }

    @Test func bindOperator_flipped() {
        let ne = NonEmpty<Int?>(head: 3)
        let fn: @Sendable (Int) -> NonEmptyTOptional<Int> = { NonEmptyTOptional(NonEmpty(head: $0 + 1)) }
        let result = fn -<< ne.nonEmptyT
        #expect(result.rawValue.toArray == [Optional(4)])
    }

    @Test func kleisliOperator_forward() {
        let f: @Sendable (Int) -> NonEmptyTOptional<Int> = { NonEmptyTOptional(NonEmpty(head: $0 + 1)) }
        let g: @Sendable (Int) -> NonEmptyTOptional<Int> = { NonEmptyTOptional(NonEmpty(head: $0 * 2)) }
        let composed = f >=> g
        #expect(composed(3).rawValue.toArray == [Optional(8)])
    }

    @Test func kleisliOperator_reverse() {
        let f: @Sendable (Int) -> NonEmptyTOptional<Int> = { NonEmptyTOptional(NonEmpty(head: $0 + 1)) }
        let g: @Sendable (Int) -> NonEmptyTOptional<Int> = { NonEmptyTOptional(NonEmpty(head: $0 * 2)) }
        let composed = g <=< f
        #expect(composed(3).rawValue.toArray == [Optional(8)])
    }
}
