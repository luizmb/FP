// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct EitherTNonEmptyApplicativeTests {
    // MARK: - apply

    @Test func apply_right_functions_right_values() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let timesTen: @Sendable (Int) -> Int = { $0 * 10 }
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .right(
            NonEmpty(head: increment, tail: [timesTen])
        )
        let values: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = applyEitherNonEmpty(functions, values)
        #expect(result == .right(NonEmpty(head: 2, tail: [3, 10, 20])))
    }

    @Test func apply_left_functions_short_circuits() {
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .left("fnErr")
        let values: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = applyEitherNonEmpty(functions, values)
        #expect(result == .left("fnErr"))
    }

    @Test func apply_left_values_short_circuits() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .right(NonEmpty(head: increment))
        let values: Either<String, NonEmpty<Int>> = .left("valErr")
        let result = applyEitherNonEmpty(functions, values)
        #expect(result == .left("valErr"))
    }

    // MARK: - liftA2

    @Test func liftA2_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10, tail: [20]))
        let result = liftA2EitherNonEmpty { (a: Int, b: Int) in a + b }(lhs, rhs)
        #expect(result == .right(NonEmpty(head: 11, tail: [21, 12, 22])))
    }

    @Test func liftA2_left_propagates() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = liftA2EitherNonEmpty { (a: Int, b: Int) in a + b }(lhs, rhs)
        #expect(result == .left("err"))
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRight_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = seqRightEitherNonEmpty(lhs, rhs)
        #expect(result == .right(NonEmpty(head: 10, tail: [10])))
    }

    @Test func seqRight_left_short_circuits() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = seqRightEitherNonEmpty(lhs, rhs)
        #expect(result == .left("err"))
    }

    @Test func seqLeft_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = seqLeftEitherNonEmpty(lhs, rhs)
        #expect(result == .right(NonEmpty(head: 1, tail: [2])))
    }

    @Test func seqLeft_left_short_circuits() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = seqLeftEitherNonEmpty(lhs, rhs)
        #expect(result == .left("err"))
    }

    // MARK: - kleisliT

    @Test func kleisliT_chains_through_right() {
        let fn1: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in .right(NonEmpty(head: n, tail: [n * 2])) }
        let fn2: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in n == 4 ? .right(nil) : .right(NonEmpty(head: n * 10)) }
        let composed = kleisliT(fn1, fn2)
        #expect(composed(2) == .right(NonEmpty(head: 20)))
    }

    @Test func kleisliT_propagates_left_from_first() {
        let fn1: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = const(.left("err"))
        let fn2: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in .right(NonEmpty(head: n)) }
        let composed = kleisliT(fn1, fn2)
        #expect(composed(1) == .left("err"))
    }

    @Test func kleisliT_short_circuits_on_nil_intermediate() {
        let fn1: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = const(.right(nil))
        let fn2: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in .right(NonEmpty(head: n)) }
        let composed = kleisliT(fn1, fn2)
        #expect(composed(1) == .right(nil))
    }
}
