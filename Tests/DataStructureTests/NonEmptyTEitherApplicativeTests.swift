// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct NonEmptyTEitherApplicativeTests {
    // MARK: - apply

    @Test func apply_right_functions_right_values() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .right(increment))
        let values = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = NonEmptyTEither.apply(fns.nonEmptyT, values.nonEmptyT).rawValue
        #expect(result.toArray == [.right(2), .right(3)])
    }

    @Test func apply_left_functions_short_circuits() {
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .left("err"))
        let values = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = NonEmptyTEither.apply(fns.nonEmptyT, values.nonEmptyT).rawValue
        // ExceptT l NonEmpty: a left on the left never runs the right side (<*> = ap)
        #expect(result.toArray == [.left("err")])
    }

    // MARK: - liftA2

    @Test func liftA2_right_right() {
        let na = NonEmpty<Either<String, Int>>(head: .right(1))
        let nb = NonEmpty<Either<String, Int>>(head: .right(10), tail: [.right(20)])
        let result = NonEmptyTEither<String, Int>.liftA2 { (a: Int, b: Int) in a + b }(na.nonEmptyT, nb.nonEmptyT).rawValue
        #expect(result.toArray == [.right(11), .right(21)])
    }

    @Test func liftA2_left_propagates() {
        let na = NonEmpty<Either<String, Int>>(head: .left("err"))
        let nb = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = NonEmptyTEither<String, Int>.liftA2 { (a: Int, b: Int) in a + b }(na.nonEmptyT, nb.nonEmptyT).rawValue
        #expect(result.toArray == [.left("err")])
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRight_right_right() {
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = lhs.nonEmptyT.seqRight(rhs.nonEmptyT).rawValue
        #expect(result.toArray == [.right(10), .right(10)])
    }

    @Test func seqRight_left_element_short_circuits_that_pairing() {
        let lhs = NonEmpty<Either<String, Int>>(head: .left("err"), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = lhs.nonEmptyT.seqRight(rhs.nonEmptyT).rawValue
        #expect(result.toArray == [.left("err"), .right(10)])
    }

    @Test func seqLeft_right_right() {
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let rhs = NonEmpty<Either<String, Int>>(head: .right(10))
        let result = lhs.nonEmptyT.seqLeft(rhs.nonEmptyT).rawValue
        #expect(result.toArray == [.right(1), .right(2)])
    }

    // MARK: - kleisli

    @Test func kleisli_chains_through_right() {
        let fn1: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in
            NonEmptyTEither(NonEmpty(head: .right(n), tail: [.right(n * 2)]))
        }
        let fn2: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in NonEmptyTEither(NonEmpty(head: .right(n * 10))) }
        let composed = NonEmptyTEither.kleisli(fn1, fn2)
        #expect(composed(2).rawValue.toArray == [.right(20), .right(40)])
    }

    @Test func kleisli_propagates_left_without_calling_second() {
        let fn1: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in NonEmptyTEither(NonEmpty(head: .left("err"), tail: [.right(n)])) }
        let fn2: @Sendable (Int) -> NonEmptyTEither<String, Int> = { n in NonEmptyTEither(NonEmpty(head: .right(n * 100))) }
        let composed = NonEmptyTEither.kleisli(fn1, fn2)
        #expect(composed(3).rawValue.toArray == [.left("err"), .right(300)])
    }
}
