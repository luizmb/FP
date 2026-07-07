// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct NonEmptyTEitherApplicativeTests {
    // MARK: - apply

    @Test func apply_right_functions_right_values() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .right(increment))
        let values = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = applyNonEmptyEither(fns, values)
        #expect(result.toArray == [.right(2), .right(3)])
    }

    @Test func apply_left_functions_short_circuits() {
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .left("err"))
        let values = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = applyNonEmptyEither(fns, values)
        #expect(result.toArray == [.left("err"), .left("err")])
    }

    // MARK: - liftA2

    @Test func liftA2_right_right() {
        let na = NonEmpty<Either<String, Int>>(head: .right(1))
        let nb = NonEmpty<Either<String, Int>>(head: .right(10), tail: [.right(20)])
        let result = liftA2NonEmptyEither { (a: Int, b: Int) in a + b }(na, nb)
        #expect(result.toArray == [.right(11), .right(21)])
    }

    @Test func liftA2_left_propagates() {
        let na = NonEmpty<Either<String, Int>>(head: .left("err"))
        let nb = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = liftA2NonEmptyEither { (a: Int, b: Int) in a + b }(na, nb)
        #expect(result.toArray == [.left("err")])
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRight_right_right() {
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = seqRightNonEmptyEither(lhs, rhs)
        #expect(result.toArray == [.right(10), .right(10)])
    }

    @Test func seqRight_left_element_short_circuits_that_pairing() {
        let lhs = NonEmpty<Either<String, Int>>(head: .left("err"), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = seqRightNonEmptyEither(lhs, rhs)
        #expect(result.toArray == [.left("err"), .right(10)])
    }

    @Test func seqLeft_right_right() {
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = seqLeftNonEmptyEither(lhs, rhs)
        #expect(result.toArray == [.right(1), .right(2)])
    }

    // MARK: - kleisliT

    @Test func kleisliT_chains_through_right() {
        let fn1: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .right(n), tail: [.right(n * 2)]) }
        let fn2: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .right(n * 10)) }
        let composed = kleisliT(fn1, fn2)
        #expect(composed(2).toArray == [.right(20), .right(40)])
    }

    @Test func kleisliT_propagates_left_without_calling_second() {
        let fn1: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .left("err"), tail: [.right(n)]) }
        let fn2: @Sendable (Int) -> NonEmpty<Either<String, Int>> = { n in NonEmpty(head: .right(n * 100)) }
        let composed = kleisliT(fn1, fn2)
        #expect(composed(3).toArray == [.left("err"), .right(300)])
    }
}
