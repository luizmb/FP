// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

private enum TestError: Error, Equatable { case bad(String) }

// Functor operators (<£^>/<&^>) for NonEmpty<Result<A, E>> are covered in
// NonEmptyTransformerOperatorsTests.swift. This suite covers Applicative and Monad operators.
@Suite struct NonEmptyTResultOperatorsTests {
    // MARK: - Applicative: <*> / *> / <*

    @Test func applyOperator_success_success() {
        let fns = NonEmpty<Result<@Sendable (Int) -> Int, TestError>>(head: .success { $0 + 1 })
        let values = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let result = fns <*> values
        #expect(result.toArray == [.success(2), .success(3)])
    }

    @Test func applyOperator_failure_short_circuits() {
        let fns = NonEmpty<Result<@Sendable (Int) -> Int, TestError>>(head: .failure(.bad("err")))
        let values = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let result = fns <*> values
        #expect(result.toArray == [.failure(.bad("err")), .failure(.bad("err"))])
    }

    @Test func seqRightOperator() {
        let lhs = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let rhs = NonEmpty<Result<Int, TestError>>(head: .success(10))
        let result = lhs *> rhs
        #expect(result.toArray == [.success(10), .success(10)])
    }

    @Test func seqLeftOperator() {
        let lhs = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let rhs = NonEmpty<Result<Int, TestError>>(head: .success(10))
        let result = lhs <* rhs
        #expect(result.toArray == [.success(1), .success(2)])
    }

    // MARK: - Monad: >>- / -<< / >=> / <=<

    @Test func bindOperator_forward() {
        let ne = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let result = ne >>- { n in NonEmpty(head: .success(n * 10)) }
        #expect(result.toArray == [.success(10), .success(20)])
    }

    @Test func bindOperator_forward_propagates_failure() {
        let ne = NonEmpty<Result<Int, TestError>>(head: .failure(.bad("err")), tail: [.success(2)])
        let result = ne >>- { n in NonEmpty(head: .success(n * 10)) }
        #expect(result.toArray == [.failure(.bad("err")), .success(20)])
    }

    @Test func bindOperator_flipped() {
        let ne = NonEmpty<Result<Int, TestError>>(head: .success(3))
        let result = { (n: Int) in NonEmpty<Result<Int, TestError>>(head: .success(n * 2)) } -<< ne
        #expect(result.toArray == [.success(6)])
    }

    @Test func kleisliOperator_forward() {
        let fn1: @Sendable (Int) -> NonEmpty<Result<Int, TestError>> = { n in
            NonEmpty(head: .success(n), tail: [.success(n * 2)])
        }
        let fn2: @Sendable (Int) -> NonEmpty<Result<Int, TestError>> = { n in NonEmpty(head: .success(n * 10)) }
        let composed = fn1 >=> fn2
        #expect(composed(2).toArray == [.success(20), .success(40)])
    }

    @Test func kleisliOperator_reverse() {
        let fn1: @Sendable (Int) -> NonEmpty<Result<Int, TestError>> = { n in
            NonEmpty(head: .success(n), tail: [.success(n * 2)])
        }
        let fn2: @Sendable (Int) -> NonEmpty<Result<Int, TestError>> = { n in NonEmpty(head: .success(n * 10)) }
        let composed = fn2 <=< fn1
        #expect(composed(2).toArray == [.success(20), .success(40)])
    }
}
