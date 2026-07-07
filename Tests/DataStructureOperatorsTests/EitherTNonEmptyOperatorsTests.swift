// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct EitherTNonEmptyOperatorsTests {
    @Test func fmapOperator_forward_right() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2, 3]))
        let result = { $0 * 10 } <£^> either
        #expect(result == .right(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func fmapOperator_forward_left() {
        let either: Either<String, NonEmpty<Int>> = .left("err")
        let result = { $0 * 10 } <£^> either
        #expect(result == .left("err"))
    }

    @Test func fmapOperator_flipped() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 5))
        let result = either <&^> { $0 + 1 }
        #expect(result == .right(NonEmpty(head: 6)))
    }

    // MARK: - Applicative operators

    @Test func applyOperator_right_functions_right_values() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let timesTen: @Sendable (Int) -> Int = { $0 * 10 }
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .right(
            NonEmpty(head: increment, tail: [timesTen])
        )
        let values: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = functions <*> values
        #expect(result == .right(NonEmpty(head: 2, tail: [3, 10, 20])))
    }

    @Test func applyOperator_left_functions_short_circuits() {
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .left("fnErr")
        let values: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = functions <*> values
        #expect(result == .left("fnErr"))
    }

    @Test func seqRightOperator_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = lhs *> rhs
        #expect(result == .right(NonEmpty(head: 10, tail: [10])))
    }

    @Test func seqRightOperator_left_short_circuits() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = lhs *> rhs
        #expect(result == .left("err"))
    }

    @Test func seqLeftOperator_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = lhs <* rhs
        #expect(result == .right(NonEmpty(head: 1, tail: [2])))
    }

    @Test func seqLeftOperator_left_short_circuits() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = lhs <* rhs
        #expect(result == .left("err"))
    }

    // MARK: - Monad operators

    @Test func bindOperator_forward_right() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = either >>- { n -> Either<String, NonEmpty<Int>?> in .right(NonEmpty(head: n * 10)) }
        #expect(result == .right(NonEmpty(head: 10, tail: [20])))
    }

    @Test func bindOperator_forward_left_propagates() {
        let either: Either<String, NonEmpty<Int>> = .left("err")
        let result = either >>- { n -> Either<String, NonEmpty<Int>?> in .right(NonEmpty(head: n * 10)) }
        #expect(result == .left("err"))
    }

    @Test func bindOperator_flipped() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 3))
        let result = { (n: Int) -> Either<String, NonEmpty<Int>?> in .right(NonEmpty(head: n + 1)) } -<< either
        #expect(result == .right(NonEmpty(head: 4)))
    }

    @Test func kleisliOperator_forward_chains_through_right() {
        let fn1: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in .right(NonEmpty(head: n, tail: [n * 2])) }
        let fn2: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in n == 4 ? .right(nil) : .right(NonEmpty(head: n * 10)) }
        let composed = fn1 >=> fn2
        #expect(composed(2) == .right(NonEmpty(head: 20)))
    }

    @Test func kleisliOperator_reverse_chains_through_right() {
        let fn1: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in .right(NonEmpty(head: n, tail: [n * 2])) }
        let fn2: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in n == 4 ? .right(nil) : .right(NonEmpty(head: n * 10)) }
        let composed = fn2 <=< fn1
        #expect(composed(2) == .right(NonEmpty(head: 20)))
    }

    @Test func kleisliOperator_reverse_propagates_left_from_first() {
        let fn1: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = const(.left("err"))
        let fn2: @Sendable (Int) -> Either<String, NonEmpty<Int>?> = { n in .right(NonEmpty(head: n)) }
        let composed = fn2 <=< fn1
        #expect(composed(1) == .left("err"))
    }
}
