// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// OptionalTNonEmpty: outer = Optional, inner = NonEmpty
// Type: NonEmpty<A>? = Optional<NonEmpty<A>>

@Suite struct OptionalTNonEmptyOperatorsTests {
    // MARK: - Functor: <£^> / <&^>

    @Test func fmapOperator_forward_present() {
        let opt: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2, 3])
        let result = { $0 * 10 } <£^> opt
        #expect(result?.toArray == [10, 20, 30])
    }

    @Test func fmapOperator_forward_nil() {
        let opt: NonEmpty<Int>? = nil
        let result = { $0 * 10 } <£^> opt
        #expect(result == nil)
    }

    @Test func fmapOperator_flipped() {
        let opt: NonEmpty<Int>? = NonEmpty(head: 5)
        let result = opt <&^> { $0 + 1 }
        #expect(result?.toArray == [6])
    }

    // MARK: - Applicative: <*> / *> / <*

    @Test func applyOperator_bothPresent() {
        let fns: NonEmpty<@Sendable (Int) -> Int>? = NonEmpty(head: { $0 + 1 }, tail: [{ $0 * 10 }])
        let values: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let result = fns <*> values
        #expect(result?.toArray == [2, 3, 10, 20])
    }

    @Test func applyOperator_nil() {
        let fns: NonEmpty<@Sendable (Int) -> Int>? = nil
        let values: NonEmpty<Int>? = NonEmpty(head: 1)
        #expect((fns <*> values) == nil)
    }

    @Test func seqRightOperator() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect((lhs *> rhs)?.toArray == ["x"])
    }

    @Test func seqLeftOperator() {
        let lhs: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let rhs: NonEmpty<String>? = NonEmpty(head: "x")
        #expect((lhs <* rhs)?.toArray == [1, 2])
    }

    // MARK: - Monad: >>- / -<< / >=> / <=<

    @Test func bindOperator_forward() {
        let opt: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let result = opt >>- { n -> NonEmpty<Int>? in n > 1 ? NonEmpty(head: n * 10) : nil }
        #expect(result?.toArray == [20])
    }

    @Test func bindOperator_flipped() {
        let opt: NonEmpty<Int>? = NonEmpty(head: 3)
        let fn: @Sendable (Int) -> NonEmpty<Int>? = { NonEmpty(head: $0 + 1) }
        let result = fn -<< opt
        #expect(result?.toArray == [4])
    }

    @Test func kleisliOperator_forward() {
        let f: @Sendable (Int) -> NonEmpty<Int>? = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int>? = { NonEmpty(head: $0 * 2) }
        let composed = f >=> g
        #expect(composed(3)?.toArray == [8])
    }

    @Test func kleisliOperator_reverse() {
        let f: @Sendable (Int) -> NonEmpty<Int>? = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int>? = { NonEmpty(head: $0 * 2) }
        let composed = g <=< f
        #expect(composed(3)?.toArray == [8])
    }
}
