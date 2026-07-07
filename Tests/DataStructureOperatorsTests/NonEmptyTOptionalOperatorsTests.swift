// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// NonEmptyTOptional: outer = NonEmpty, inner = Optional
// Type: NonEmpty<A?> = NonEmpty<Optional<A>>
// Functor operators (<£^> / <&^>) for this combo are covered in NonEmptyTransformerOperatorsTests.swift

@Suite struct NonEmptyTOptionalOperatorsTests {
    // MARK: - Applicative: <*> / *> / <*

    @Test func applyOperator_cartesianProduct() {
        let fns = NonEmpty<(@Sendable (Int) -> Int)?>(head: { $0 + 1 }, tail: [nil])
        let values = NonEmpty<Int?>(head: 1, tail: [2])
        let result = fns <*> values
        #expect(result.toArray == [Optional(2), Optional(3), nil, nil])
    }

    @Test func seqRightOperator() {
        let lhs = NonEmpty<Int?>(head: 1, tail: [nil])
        let rhs = NonEmpty<String?>(head: "x")
        #expect((lhs *> rhs).toArray == [Optional("x"), nil])
    }

    @Test func seqLeftOperator() {
        let lhs = NonEmpty<Int?>(head: 1, tail: [nil])
        let rhs = NonEmpty<String?>(head: "x")
        #expect((lhs <* rhs).toArray == [Optional(1), nil])
    }

    // MARK: - Monad: >>- / -<< / >=> / <=<

    @Test func bindOperator_forward() {
        let ne = NonEmpty<Int?>(head: 2, tail: [nil])
        let result = ne >>- { n in NonEmpty<Int?>(head: n * 2) }
        #expect(result.toArray == [Optional(4), nil])
    }

    @Test func bindOperator_flipped() {
        let ne = NonEmpty<Int?>(head: 3)
        let fn: @Sendable (Int) -> NonEmpty<Int?> = { NonEmpty(head: $0 + 1) }
        let result = fn -<< ne
        #expect(result.toArray == [Optional(4)])
    }

    @Test func kleisliOperator_forward() {
        let f: @Sendable (Int) -> NonEmpty<Int?> = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int?> = { NonEmpty(head: $0 * 2) }
        let composed = f >=> g
        #expect(composed(3).toArray == [Optional(8)])
    }

    @Test func kleisliOperator_reverse() {
        let f: @Sendable (Int) -> NonEmpty<Int?> = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int?> = { NonEmpty(head: $0 * 2) }
        let composed = g <=< f
        #expect(composed(3).toArray == [Optional(8)])
    }
}
