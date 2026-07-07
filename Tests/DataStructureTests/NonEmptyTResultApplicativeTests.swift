// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

private enum TestError: Error, Equatable { case bad(String) }

@Suite struct NonEmptyTResultApplicativeTests {
    // MARK: - apply

    @Test func apply_success_functions_success_values() {
        let fns = NonEmpty<Result<@Sendable (Int) -> Int, TestError>>(head: .success { $0 + 1 })
        let values = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let result = applyNonEmptyResult(fns, values)
        #expect(result.toArray == [.success(2), .success(3)])
    }

    @Test func apply_failure_functions_short_circuits() {
        let fns = NonEmpty<Result<@Sendable (Int) -> Int, TestError>>(head: .failure(.bad("err")))
        let values = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let result = applyNonEmptyResult(fns, values)
        #expect(result.toArray == [.failure(.bad("err")), .failure(.bad("err"))])
    }

    // MARK: - liftA2

    @Test func liftA2_success_success() {
        let na = NonEmpty<Result<Int, TestError>>(head: .success(1))
        let nb = NonEmpty<Result<Int, TestError>>(head: .success(10), tail: [.success(20)])
        let result = liftA2NonEmptyResult { (a: Int, b: Int) in a + b }(na, nb)
        #expect(result.toArray == [.success(11), .success(21)])
    }

    @Test func liftA2_failure_propagates() {
        let na = NonEmpty<Result<Int, TestError>>(head: .failure(.bad("err")))
        let nb = NonEmpty<Result<Int, TestError>>(head: .success(10))
        let result = liftA2NonEmptyResult { (a: Int, b: Int) in a + b }(na, nb)
        #expect(result.toArray == [.failure(.bad("err"))])
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRight_success_success() {
        let lhs = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let rhs = NonEmpty<Result<Int, TestError>>(head: .success(10))
        let result = seqRightNonEmptyResult(lhs, rhs)
        #expect(result.toArray == [.success(10), .success(10)])
    }

    @Test func seqRight_failure_element_short_circuits_that_pairing() {
        let lhs = NonEmpty<Result<Int, TestError>>(head: .failure(.bad("err")), tail: [.success(2)])
        let rhs = NonEmpty<Result<Int, TestError>>(head: .success(10))
        let result = seqRightNonEmptyResult(lhs, rhs)
        #expect(result.toArray == [.failure(.bad("err")), .success(10)])
    }

    @Test func seqLeft_success_success() {
        let lhs = NonEmpty<Result<Int, TestError>>(head: .success(1), tail: [.success(2)])
        let rhs = NonEmpty<Result<Int, TestError>>(head: .success(10))
        let result = seqLeftNonEmptyResult(lhs, rhs)
        #expect(result.toArray == [.success(1), .success(2)])
    }

    // MARK: - kleisliT

    @Test func kleisliT_chains_through_success() {
        let fn1: @Sendable (Int) -> NonEmpty<Result<Int, TestError>> = { n in
            NonEmpty(head: .success(n), tail: [.success(n * 2)])
        }
        let fn2: @Sendable (Int) -> NonEmpty<Result<Int, TestError>> = { n in NonEmpty(head: .success(n * 10)) }
        let composed = kleisliT(fn1, fn2)
        #expect(composed(2).toArray == [.success(20), .success(40)])
    }

    @Test func kleisliT_propagates_failure_without_calling_second() {
        let fn1: @Sendable (Int) -> NonEmpty<Result<Int, TestError>> = { n in
            NonEmpty(head: .failure(.bad("err")), tail: [.success(n)])
        }
        let fn2: @Sendable (Int) -> NonEmpty<Result<Int, TestError>> = { n in NonEmpty(head: .success(n * 100)) }
        let composed = kleisliT(fn1, fn2)
        #expect(composed(3).toArray == [.failure(.bad("err")), .success(300)])
    }
}
