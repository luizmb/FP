// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

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

    // MARK: - Applicative operators

    @Test func applyOperator_right_functions_right_values() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .right(increment))
        let values = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = fns <*> values
        #expect(result.toArray == [.right(2), .right(3)])
    }

    @Test func applyOperator_left_functions_short_circuits() {
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .left("err"))
        let values = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = fns <*> values
        #expect(result.toArray == [.left("err"), .left("err")])
    }

    @Test func seqRightOperator_right_right() {
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = lhs *> rhs
        #expect(result.toArray == [.right(10), .right(10)])
    }

    @Test func seqRightOperator_left_element_short_circuits_that_pairing() {
        let lhs = NonEmpty<Either<String, Int>>(head: .left("err"), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = lhs *> rhs
        #expect(result.toArray == [.left("err"), .right(10)])
    }

    @Test func seqLeftOperator_right_right() {
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = lhs <* rhs
        #expect(result.toArray == [.right(1), .right(2)])
    }

    // MARK: - Monad operators

    @Test func bindOperator_forward() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = ne >>- { n in NonEmpty<Either<String, Int>>(head: .right(n), tail: [.right(n * 10)]) }
        #expect(result.toArray == [.right(1), .right(10), .right(2), .right(20)])
    }

    @Test func bindOperator_flipped() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(3))
        let result = { (n: Int) in NonEmpty<Either<String, Int>>(head: .right(n + 1)) } -<< ne
        #expect(result.toArray == [.right(4)])
    }

    @Test func kleisliOperator_forward_chains_through_right() {
        let fn1: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .right(n), tail: [.right(n * 2)]) }
        let fn2: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .right(n * 10)) }
        let composed = fn1 >=> fn2
        #expect(composed(2).toArray == [.right(20), .right(40)])
    }

    @Test func kleisliOperator_reverse_chains_through_right() {
        let fn1: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .right(n), tail: [.right(n * 2)]) }
        let fn2: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .right(n * 10)) }
        let composed = fn2 <=< fn1
        #expect(composed(2).toArray == [.right(20), .right(40)])
    }

    @Test func kleisliOperator_reverse_propagates_left_without_calling_second() {
        let fn1: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .left("err"), tail: [.right(n)]) }
        let fn2: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .right(n * 100)) }
        let composed = fn2 <=< fn1
        #expect(composed(3).toArray == [.left("err"), .right(300)])
    }
}
