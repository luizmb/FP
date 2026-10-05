// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct NonEmptyTEitherOperatorsTests {
    // MARK: - Applicative operators

    @Test func applyOperator_right_functions_right_values() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .right(increment))
        let values = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = (fns.nonEmptyT <*> values.nonEmptyT).rawValue
        #expect(result.toArray == [.right(2), .right(3)])
    }

    @Test func applyOperator_left_functions_short_circuits() {
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .left("err"))
        let values = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = (fns.nonEmptyT <*> values.nonEmptyT).rawValue
        // ExceptT l NonEmpty: a left on the left never runs the right side (<*> = ap)
        #expect(result.toArray == [.left("err")])
    }

    @Test func seqRightOperator_right_right() {
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = (lhs.nonEmptyT *> rhs.nonEmptyT).rawValue
        #expect(result.toArray == [.right(10), .right(10)])
    }

    @Test func seqRightOperator_left_element_short_circuits_that_pairing() {
        let lhs = NonEmpty<Either<String, Int>>(head: .left("err"), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = (lhs.nonEmptyT *> rhs.nonEmptyT).rawValue
        #expect(result.toArray == [.left("err"), .right(10)])
    }

    @Test func seqLeftOperator_right_right() {
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = (lhs.nonEmptyT <* rhs.nonEmptyT).rawValue
        #expect(result.toArray == [.right(1), .right(2)])
    }

    // MARK: - Monad operators

    @Test func bindOperator_forward() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = ne.nonEmptyT >>- { n in NonEmptyTEither(NonEmpty<Either<String, Int>>(head: .right(n), tail: [.right(n * 10)])) }
        #expect(result.rawValue.toArray == [.right(1), .right(10), .right(2), .right(20)])
    }

    @Test func bindOperator_flipped() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(3))
        let result = { (n: Int) in NonEmptyTEither(NonEmpty<Either<String, Int>>(head: .right(n + 1))) } -<< ne.nonEmptyT
        #expect(result.rawValue.toArray == [.right(4)])
    }

    @Test func kleisliOperator_forward_chains_through_right() {
        let fn1: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in
            NonEmptyTEither(NonEmpty(head: .right(n), tail: [.right(n * 2)]))
        }
        let fn2: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in NonEmptyTEither(NonEmpty(head: .right(n * 10))) }
        let composed = fn1 >=> fn2
        #expect(composed(2).rawValue.toArray == [.right(20), .right(40)])
    }

    @Test func kleisliOperator_reverse_chains_through_right() {
        let fn1: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in
            NonEmptyTEither(NonEmpty(head: .right(n), tail: [.right(n * 2)]))
        }
        let fn2: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in NonEmptyTEither(NonEmpty(head: .right(n * 10))) }
        let composed = fn2 <=< fn1
        #expect(composed(2).rawValue.toArray == [.right(20), .right(40)])
    }

    @Test func kleisliOperator_reverse_propagates_left_without_calling_second() {
        let fn1: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in NonEmptyTEither(NonEmpty(head: .left("err"), tail: [.right(n)])) }
        let fn2: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in NonEmptyTEither(NonEmpty(head: .right(n * 100))) }
        let composed = fn2 <=< fn1
        #expect(composed(3).rawValue.toArray == [.left("err"), .right(300)])
    }
}
